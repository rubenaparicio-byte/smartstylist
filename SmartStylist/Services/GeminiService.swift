import Foundation

// ── Garment vision types ─────────────────────────────────────────────────────

struct GarmentPrediction: Codable {
    let category: String
    let primaryColor: String
    let pattern: String
    let style: String
    let tags: [String]
}

struct BulkScanResult: Codable {
    let items: [GarmentPrediction]
}

// ── Colorimetry result types ──────────────────────────────────────────────────

struct ColorSwatch: Codable, Hashable {
    let name: String
    let hex: String
}

struct ColorimetryAnalysis: Codable {
    let season: String
    let guidelines: String
    let recommendedColors: [ColorSwatch]
    let avoidColors: [ColorSwatch]
    let metalPreference: String

    enum CodingKeys: String, CodingKey {
        case season, guidelines
        case recommendedColors = "recommended_colors"
        case avoidColors       = "avoid_colors"
        case metalPreference   = "metal_preference"
    }
}

// ── Service ───────────────────────────────────────────────────────────────────

final class GeminiService {
    private let apiKey   = APIKeys.openRouter
    private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    // Tried in order; skips to next on 404 / 429 / 503 (retriable).
    private let textModels: [String] = [
        "google/gemma-3-27b-it:free",
        "meta-llama/llama-4-maverick:free",
        "meta-llama/llama-4-scout:free",
        "qwen/qwen-2.5-72b-instruct:free"
    ]
    private let visionModels: [String] = [
        "google/gemma-3-27b-it:free",
        "meta-llama/llama-4-scout:free",
        "meta-llama/llama-4-maverick:free"
    ]

    // ── Text generation ───────────────────────────────────────────────────────

    func generate(prompt: String) async throws -> String {
        let body: [String: Any] = [
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.7,
            "max_tokens": 2048,
            "response_format": ["type": "json_object"]
        ]
        return try await postWithFallback(body: body, models: textModels, context: "generate()")
    }

    // ── Colorimetry analysis ──────────────────────────────────────────────────

    func analyseProfile(bodyType: String, skinTone: String,
                        eyeColor: String, hairColor: String) async throws -> ColorimetryAnalysis {
        let prompt = """
        You are a luxury fashion consultant and certified colour analyst.
        Analyse the physical profile below and respond ONLY with a valid JSON object.
        No markdown, no code fences, no extra text — raw JSON only.

        Required JSON schema:
        {
          "season": "Spring|Summer|Autumn|Winter",
          "guidelines": "2-3 sentences of personalised seasonal colour harmony guidance",
          "recommended_colors": [
            {"name": "Color Name", "hex": "#RRGGBB"},
            {"name": "Color Name", "hex": "#RRGGBB"},
            {"name": "Color Name", "hex": "#RRGGBB"},
            {"name": "Color Name", "hex": "#RRGGBB"},
            {"name": "Color Name", "hex": "#RRGGBB"},
            {"name": "Color Name", "hex": "#RRGGBB"}
          ],
          "avoid_colors": [
            {"name": "Color Name", "hex": "#RRGGBB"},
            {"name": "Color Name", "hex": "#RRGGBB"},
            {"name": "Color Name", "hex": "#RRGGBB"}
          ],
          "metal_preference": "Gold|Silver|Rose Gold"
        }

        Profile:
        - Body type: \(bodyType)
        - Skin tone: \(skinTone)
        - Eye colour: \(eyeColor)
        - Hair colour: \(hairColor)
        """
        let raw = try await generate(prompt: prompt)
        let cleaned = stripMarkdownFences(raw)
        guard let data = cleaned.data(using: .utf8) else { throw LLMError.parseError }
        do {
            return try JSONDecoder().decode(ColorimetryAnalysis.self, from: data)
        } catch {
            await DebugLogger.shared.log("analyseProfile() parseError: \(error.localizedDescription) — raw: \(String(cleaned.prefix(300)))")
            throw LLMError.parseError
        }
    }

    // ── Outfit suggestion ─────────────────────────────────────────────────────

    func suggestOutfit(profileJSON: String,
                       weatherJSON: String,
                       inventoryJSON: String,
                       historyJSON: String,
                       occasion: String) async throws -> StyleResponse {
        let prompt = """
        You are an elite personal stylist with expertise in colour theory, seasonal fashion, and dress codes.
        Respond ONLY with a valid JSON object matching this schema exactly. No markdown, no code fences.

        {
          "clima_procesado": "temperature + condition string",
          "analisis_contexto": "2-3 sentence premium justification for why this look is ideal today",
          "outfit_sugerido": {
            "superior_id": "UUID string or null",
            "inferior_id": "UUID string or null",
            "calzado_id":  "UUID string or null",
            "abrigo_id":   "UUID string or null"
          },
          "consejo_estilo": "one personalised tip to elevate the outfit"
        }

        STRICT RULES — each violation degrades the quality of the recommendation:
        1. INVENTORY: Use ONLY UUIDs present in the active wardrobe below. Never invent or reuse UUIDs.
        2. RADICAL VARIETY — CRITICAL:
           - Cross-reference all item IDs from the 14-day history.
           - Any item appearing 3 or more times in the last 14 days MUST be rested today.
           - NEVER reproduce an identical outfit combination from the history.
           - The new outfit must differ by at least 2 pieces from the most recently worn look.
        3. THERMAL COHERENCE:
           - If requiresUmbrella is true → abrigo_id is MANDATORY and must be weather-resistant.
           - If temp < 10°C → abrigo_id is MANDATORY for warmth.
           - If temp > 24°C → abrigo_id should be null unless the event strictly requires it.
        4. EVENT PROTOCOL: Every piece must respect the formality and dress code of the occasion.
        5. COLOUR HARMONY: Prioritise pieces that complement the user's seasonal colorimetry palette.

        === USER PROFILE ===
        \(profileJSON)

        === CURRENT WEATHER ===
        \(weatherJSON)

        === OCCASION & DRESS CODE ===
        \(occasion)

        === ACTIVE WARDROBE (use only these UUIDs) ===
        \(inventoryJSON)

        === LAST 14 DAYS HISTORY (avoid repeating these combinations) ===
        \(historyJSON)
        """
        let raw = try await generate(prompt: prompt)
        let cleaned = stripMarkdownFences(raw)
        guard let data = cleaned.data(using: .utf8) else { throw LLMError.parseError }
        do { return try JSONDecoder().decode(StyleResponse.self, from: data) }
        catch {
            await DebugLogger.shared.log("suggestOutfit() parseError: \(error.localizedDescription) — raw: \(String(cleaned.prefix(300)))")
            throw LLMError.parseError
        }
    }

    // ── Vision: single item ───────────────────────────────────────────────────

    func analyseClothingItem(imageData: Data,
                             mimeType: String = "image/jpeg") async throws -> GarmentPrediction {
        let prompt = """
        You are a professional fashion cataloguer with computer vision expertise.
        Analyse this clothing item image and respond ONLY with a valid JSON object.
        No markdown, no code fences — raw JSON only.

        Required JSON schema:
        {
          "category": "superior|inferior|calzado|abrigo|accesorio",
          "primaryColor": "#RRGGBB",
          "pattern": "Solid|Stripes|Checks|Floral|Abstract|Animal Print",
          "style": "Casual|Formal|Smart Casual|Athletic|Evening",
          "tags": ["occasion1", "occasion2", "occasion3"]
        }
        """
        let raw = try await postWithImage(imageData: imageData, mimeType: mimeType,
                                          prompt: prompt, context: "analyseClothingItem()")
        let cleaned = stripMarkdownFences(raw)
        guard let data = cleaned.data(using: .utf8) else { throw LLMError.parseError }
        do { return try JSONDecoder().decode(GarmentPrediction.self, from: data) }
        catch {
            await DebugLogger.shared.log("analyseClothingItem() parseError: \(error.localizedDescription) — raw: \(String(cleaned.prefix(300)))")
            throw LLMError.parseError
        }
    }

    // ── Vision: bulk wardrobe scan ────────────────────────────────────────────

    func scanBulkWardrobe(imageData: Data,
                          mimeType: String = "image/jpeg") async throws -> [GarmentPrediction] {
        let prompt = """
        You are a professional fashion cataloguer with computer vision expertise.
        Identify every distinct clothing item visible in this image.
        Respond ONLY with a valid JSON object — no markdown, no code fences.

        Required JSON schema:
        {
          "items": [
            {
              "category": "superior|inferior|calzado|abrigo|accesorio",
              "primaryColor": "#RRGGBB",
              "pattern": "Solid|Stripes|Checks|Floral|Abstract|Animal Print",
              "style": "Casual|Formal|Smart Casual|Athletic|Evening",
              "tags": ["occasion1", "occasion2"]
            }
          ]
        }

        Return 1–12 items. Include only clearly distinct garments.
        """
        let raw = try await postWithImage(imageData: imageData, mimeType: mimeType,
                                          prompt: prompt, context: "scanBulkWardrobe()")
        let cleaned = stripMarkdownFences(raw)
        guard let data = cleaned.data(using: .utf8) else { throw LLMError.parseError }
        do { return try JSONDecoder().decode(BulkScanResult.self, from: data).items }
        catch {
            await DebugLogger.shared.log("scanBulkWardrobe() parseError: \(error.localizedDescription) — raw: \(String(cleaned.prefix(300)))")
            throw LLMError.parseError
        }
    }

    // ── Diagnostics ───────────────────────────────────────────────────────────

    func logFreeModels() async {
        guard let url = URL(string: "https://openrouter.ai/api/v1/models") else { return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["data"] as? [[String: Any]] else {
            await DebugLogger.shared.log("logFreeModels: failed to fetch catalog")
            return
        }
        let free = models.compactMap { m -> String? in
            guard let id = m["id"] as? String,
                  let pricing = m["pricing"] as? [String: Any],
                  let prompt = pricing["prompt"] as? String,
                  prompt == "0" else { return nil }
            return id
        }
        await DebugLogger.shared.log("FREE models (\(free.count)): \(free.joined(separator: ", "))")
    }

    // ── Request helpers ───────────────────────────────────────────────────────

    private func postWithImage(imageData: Data, mimeType: String,
                               prompt: String, context: String) async throws -> String {
        let dataURL = "data:\(mimeType);base64,\(imageData.base64EncodedString())"
        let body: [String: Any] = [
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image_url", "image_url": ["url": dataURL]],
                    ["type": "text", "text": prompt]
                ]
            ]],
            "temperature": 0.3,
            "max_tokens": 1024
        ]
        return try await postWithFallback(body: body, models: visionModels, context: context)
    }

    private func postWithFallback(body: [String: Any], models: [String], context: String) async throws -> String {
        var lastStatus = 0
        var lastData   = Data()

        for model in models {
            var b = body
            b["model"] = model
            do {
                let (data, status) = try await send(body: b)
                if status == 200 {
                    return try extractText(from: data, context: "\(context)[\(model)]")
                }
                lastStatus = status
                lastData   = data
                await logAPIError(context: "\(context)[\(model)]", statusCode: status, data: data)
                let retriable = status == 404 || status == 429 || status == 503
                if !retriable { throw LLMError.serverError }
            } catch let e as LLMError {
                throw e
            } catch {
                await DebugLogger.shared.log("\(context)[\(model)] network: \(error.localizedDescription)")
            }
        }

        await logAPIError(context: "\(context)[exhausted]", statusCode: lastStatus, data: lastData)
        throw LLMError.serverError
    }

    private func send(body: [String: Any]) async throws -> (Data, Int) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("SmartStylist", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        return (data, status)
    }

    private func extractText(from data: Data, context: String) throws -> String {
        let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        guard let text = message?["content"] as? String else {
            let reason = choices?.first?["finish_reason"] as? String
            Task { await DebugLogger.shared.log("\(context) emptyResponse — finish_reason: \(reason ?? "nil")") }
            throw LLMError.emptyResponse
        }
        return text
    }

    private func stripMarkdownFences(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```") {
            let lines = s.components(separatedBy: "\n")
            s = lines.dropFirst().dropLast().joined(separator: "\n")
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func logAPIError(context: String, statusCode: Int, data: Data) async {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let err  = json["error"] as? [String: Any] {
            let msg      = err["message"] as? String ?? "?"
            let type     = err["type"] as? String ?? err["status"] as? String ?? ""
            let metadata = err["metadata"] as? [String: Any]
            let provider = metadata?["provider_name"] as? String ?? ""
            let parts    = [type, provider.isEmpty ? nil : "via \(provider)"].compactMap { $0 }
            let detail   = parts.isEmpty ? "" : " [\(parts.joined(separator: " "))]"
            await DebugLogger.shared.log("\(context) \(statusCode)\(detail): \(msg)")
        } else {
            let raw = String(data: data, encoding: .utf8) ?? "<binary>"
            await DebugLogger.shared.log("\(context) HTTP \(statusCode): \(String(raw.prefix(300)))")
        }
    }
}

// ── Errors ────────────────────────────────────────────────────────────────────

enum LLMError: LocalizedError {
    case serverError, emptyResponse, parseError
    var errorDescription: String? {
        switch self {
        case .serverError:   return "AI service error. Please try again."
        case .emptyResponse: return "The AI returned an empty response."
        case .parseError:    return "Could not parse the AI response."
        }
    }
}

// Kept for source compatibility with ViewModels that catch GeminiError.
typealias GeminiError = LLMError
