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
    private let apiKey      = APIKeys.openRouter
    private let endpoint    = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private let textModel   = "deepseek/deepseek-chat:free"
    private let visionModel = "google/gemma-3-27b-it:free"

    // ── Text generation ───────────────────────────────────────────────────────

    func generate(prompt: String) async throws -> String {
        let body: [String: Any] = [
            "model": textModel,
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.7,
            "max_tokens": 2048,
            "response_format": ["type": "json_object"]
        ]
        return try await post(body: body, context: "generate()")
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
        guard let data = cleaned.data(using: .utf8) else { throw GeminiError.parseError }
        do {
            return try JSONDecoder().decode(ColorimetryAnalysis.self, from: data)
        } catch {
            await DebugLogger.shared.log("analyseProfile() parseError: \(error.localizedDescription) — raw: \(String(cleaned.prefix(300)))")
            throw GeminiError.parseError
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
        guard let data = cleaned.data(using: .utf8) else { throw GeminiError.parseError }
        do { return try JSONDecoder().decode(StyleResponse.self, from: data) }
        catch {
            await DebugLogger.shared.log("suggestOutfit() parseError: \(error.localizedDescription) — raw: \(String(cleaned.prefix(300)))")
            throw GeminiError.parseError
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
        let raw = try await postWithImage(imageData: imageData, mimeType: mimeType, prompt: prompt,
                                          context: "analyseClothingItem()")
        let cleaned = stripMarkdownFences(raw)
        guard let data = cleaned.data(using: .utf8) else { throw GeminiError.parseError }
        do { return try JSONDecoder().decode(GarmentPrediction.self, from: data) }
        catch {
            await DebugLogger.shared.log("analyseClothingItem() parseError: \(error.localizedDescription) — raw: \(String(cleaned.prefix(300)))")
            throw GeminiError.parseError
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
        let raw = try await postWithImage(imageData: imageData, mimeType: mimeType, prompt: prompt,
                                          context: "scanBulkWardrobe()")
        let cleaned = stripMarkdownFences(raw)
        guard let data = cleaned.data(using: .utf8) else { throw GeminiError.parseError }
        do { return try JSONDecoder().decode(BulkScanResult.self, from: data).items }
        catch {
            await DebugLogger.shared.log("scanBulkWardrobe() parseError: \(error.localizedDescription) — raw: \(String(cleaned.prefix(300)))")
            throw GeminiError.parseError
        }
    }

    // ── OpenRouter request helpers ────────────────────────────────────────────

    private func post(body: [String: Any], context: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("SmartStylist", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            await DebugLogger.shared.log("\(context) network: \(error.localizedDescription)")
            throw GeminiError.serverError
        }

        let http = response as? HTTPURLResponse
        guard http?.statusCode == 200 else {
            await logAPIError(context: context, statusCode: http?.statusCode ?? -1, data: data)
            throw GeminiError.serverError
        }

        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        guard let text = message?["content"] as? String else {
            let finishReason = choices?.first?["finish_reason"] as? String
            await DebugLogger.shared.log("\(context) emptyResponse — finish_reason: \(finishReason ?? "nil")")
            throw GeminiError.emptyResponse
        }
        return text
    }

    private func postWithImage(imageData: Data, mimeType: String,
                               prompt: String, context: String) async throws -> String {
        let dataURL = "data:\(mimeType);base64,\(imageData.base64EncodedString())"
        let body: [String: Any] = [
            "model": visionModel,
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
        return try await post(body: body, context: context)
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
            let rawErr   = metadata?["raw"] as? String ?? ""
            let detail   = [type, provider.isEmpty ? nil : "via \(provider)", rawErr.isEmpty ? nil : rawErr]
                .compactMap { $0 }.joined(separator: " ")
            await DebugLogger.shared.log("\(context) \(statusCode) \(detail.isEmpty ? "" : "[\(detail)]"): \(msg)")
        } else {
            let raw = String(data: data, encoding: .utf8) ?? "<binary>"
            await DebugLogger.shared.log("\(context) HTTP \(statusCode): \(String(raw.prefix(300)))")
        }
    }
}

enum GeminiError: LocalizedError {
    case serverError, emptyResponse, parseError
    var errorDescription: String? {
        switch self {
        case .serverError:    return "Gemini API server error."
        case .emptyResponse:  return "Gemini returned an empty response."
        case .parseError:     return "Could not parse Gemini response."
        }
    }
}
