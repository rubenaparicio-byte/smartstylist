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
    private let apiKey = APIKeys.gemini
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

    func generate(prompt: String) async throws -> String {
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2048,
                "responseMimeType": "application/json"
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw GeminiError.serverError
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content    = candidates?.first?["content"] as? [String: Any]
        let parts      = content?["parts"] as? [[String: Any]]
        guard let text = parts?.first?["text"] as? String else {
            throw GeminiError.emptyResponse
        }
        return text
    }

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
            throw GeminiError.parseError
        }
    }

    // Strips markdown code fences that the model sometimes wraps around JSON
    private func stripMarkdownFences(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```") {
            let lines = s.components(separatedBy: "\n")
            s = lines.dropFirst().dropLast().joined(separator: "\n")
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

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
        catch { throw GeminiError.parseError }
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
        let raw = try await generateWithImage(imageData: imageData, mimeType: mimeType, prompt: prompt)
        let cleaned = stripMarkdownFences(raw)
        guard let data = cleaned.data(using: .utf8) else { throw GeminiError.parseError }
        do { return try JSONDecoder().decode(GarmentPrediction.self, from: data) }
        catch { throw GeminiError.parseError }
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
        let raw = try await generateWithImage(imageData: imageData, mimeType: mimeType, prompt: prompt)
        let cleaned = stripMarkdownFences(raw)
        guard let data = cleaned.data(using: .utf8) else { throw GeminiError.parseError }
        do { return try JSONDecoder().decode(BulkScanResult.self, from: data).items }
        catch { throw GeminiError.parseError }
    }

    // ── Multimodal request helper ─────────────────────────────────────────────

    private func generateWithImage(imageData: Data,
                                   mimeType: String,
                                   prompt: String) async throws -> String {
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["inline_data": ["mime_type": mimeType, "data": imageData.base64EncodedString()]],
                    ["text": prompt]
                ]
            ]],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 1024,
                "responseMimeType": "application/json"
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw GeminiError.serverError
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content    = candidates?.first?["content"] as? [String: Any]
        let parts      = content?["parts"] as? [[String: Any]]
        guard let text = parts?.first?["text"] as? String else { throw GeminiError.emptyResponse }
        return text
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
