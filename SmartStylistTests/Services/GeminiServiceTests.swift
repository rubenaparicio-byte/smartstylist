import XCTest
@testable import SmartStylist

// ── Mock URLProtocol ──────────────────────────────────────────────────────────
// Intercepts URLSession requests and returns pre-configured responses so no
// real network calls are made during tests.

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private func openRouterResponse(statusCode: Int, body: String) throws -> (HTTPURLResponse, Data) {
    let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    let response = HTTPURLResponse(url: url, statusCode: statusCode,
                                   httpVersion: nil, headerFields: nil)!
    return (response, Data(body.utf8))
}

// Wraps text as a valid OpenRouter choices JSON envelope.
private func choicesEnvelope(_ content: String) -> String {
    let escaped = content.replacingOccurrences(of: "\\", with: "\\\\")
                         .replacingOccurrences(of: "\"", with: "\\\"")
    return "{\"choices\":[{\"message\":{\"content\":\"\(escaped)\"}}]}"
}

// ── GeminiServiceTests ────────────────────────────────────────────────────────

final class GeminiServiceTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func test_styleResponse_fullDecode() throws {
        let json = """
        {
          "clima_procesado": "15°C, Cloudy",
          "analisis_contexto": "A cool overcast day is perfect for layered wool tones.",
          "outfit_sugerido": {
            "superior_id": "11111111-1111-1111-1111-111111111111",
            "inferior_id": "22222222-2222-2222-2222-222222222222",
            "calzado_id":  "33333333-3333-3333-3333-333333333333",
            "abrigo_id":   "44444444-4444-4444-4444-444444444444"
          },
          "consejo_estilo": "Tuck in the front of your shirt for a smart-casual finish."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StyleResponse.self, from: json)
        XCTAssertEqual(response.climaProcesado, "15°C, Cloudy")
        XCTAssertEqual(response.outfitSugerido.allItemIds.count, 4)
        XCTAssertFalse(response.consejoEstilo.isEmpty)
    }

    func test_styleResponse_missingAbrigo_allItemIds_is3() throws {
        let json = """
        {
          "clima_procesado": "25°C, Sunny",
          "analisis_contexto": "Warm and bright.",
          "outfit_sugerido": {
            "superior_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            "inferior_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
            "calzado_id":  "cccccccc-cccc-cccc-cccc-cccccccccccc",
            "abrigo_id":   null
          },
          "consejo_estilo": "Opt for breathable linen today."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StyleResponse.self, from: json)
        XCTAssertNil(response.outfitSugerido.abrigo)
        XCTAssertEqual(response.outfitSugerido.allItemIds.count, 3)
    }

    // ── LLMError.serverError — all models exhausted ───────────────────────────

    func test_generate_allModels429_throwsServerError() async {
        MockURLProtocol.requestHandler = { request in
            try openRouterResponse(statusCode: 429, body: "{}")
        }
        let svc = GeminiService(session: makeMockSession())
        do {
            _ = try await svc.generate(prompt: "test")
            XCTFail("Expected LLMError.serverError")
        } catch LLMError.serverError {
            // expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_generate_allModels503_throwsServerError() async {
        MockURLProtocol.requestHandler = { request in
            try openRouterResponse(statusCode: 503, body: "{}")
        }
        let svc = GeminiService(session: makeMockSession())
        do {
            _ = try await svc.generate(prompt: "test")
            XCTFail("Expected LLMError.serverError")
        } catch LLMError.serverError {
            // expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // ── LLMError.serverError — non-retriable status stops immediately ─────────

    func test_generate_nonRetriable500_throwsServerErrorAfterFirstModel() async {
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            return try openRouterResponse(statusCode: 500, body: "{}")
        }
        let svc = GeminiService(session: makeMockSession())
        do {
            _ = try await svc.generate(prompt: "test")
            XCTFail("Expected LLMError.serverError")
        } catch LLMError.serverError {
            XCTAssertEqual(callCount, 1, "Non-retriable 500 should not retry further models")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // ── Model fallback: 404 on first, 200 on second ───────────────────────────

    func test_generate_firstModel404_fallsBackToSecondModel() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if callCount == 1 {
                return try openRouterResponse(statusCode: 404, body: "{}")
            }
            let body = choicesEnvelope("{\"result\":\"ok\"}")
            return try openRouterResponse(statusCode: 200, body: body)
        }
        let svc = GeminiService(session: makeMockSession())
        let result = try await svc.generate(prompt: "test")
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(callCount, 2, "Should try second model after 404")
    }

    // ── LLMError.emptyResponse ────────────────────────────────────────────────

    func test_generate_emptyChoicesArray_throwsEmptyResponse() async {
        MockURLProtocol.requestHandler = { request in
            try openRouterResponse(statusCode: 200, body: "{\"choices\":[]}")
        }
        let svc = GeminiService(session: makeMockSession())
        do {
            _ = try await svc.generate(prompt: "test")
            XCTFail("Expected LLMError.emptyResponse")
        } catch LLMError.emptyResponse {
            // expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_generate_noContentField_throwsEmptyResponse() async {
        let body = "{\"choices\":[{\"message\":{\"role\":\"assistant\"}}]}"
        MockURLProtocol.requestHandler = { request in
            try openRouterResponse(statusCode: 200, body: body)
        }
        let svc = GeminiService(session: makeMockSession())
        do {
            _ = try await svc.generate(prompt: "test")
            XCTFail("Expected LLMError.emptyResponse")
        } catch LLMError.emptyResponse {
            // expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // ── LLMError.parseError ───────────────────────────────────────────────────

    func test_analyseProfile_malformedJSON_throwsParseError() async {
        MockURLProtocol.requestHandler = { request in
            let body = choicesEnvelope("this is not json at all")
            return try openRouterResponse(statusCode: 200, body: body)
        }
        let svc = GeminiService(session: makeMockSession())
        do {
            _ = try await svc.analyseProfile(gender: "Male", bodyType: "Athletic",
                                              skinTone: "warm_light",
                                              eyeColor: "Brown", hairColor: "Black")
            XCTFail("Expected LLMError.parseError")
        } catch LLMError.parseError {
            // expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_suggestOutfit_malformedJSON_throwsParseError() async {
        MockURLProtocol.requestHandler = { request in
            let body = choicesEnvelope("{\"unexpected_key\": true}")
            return try openRouterResponse(statusCode: 200, body: body)
        }
        let svc = GeminiService(session: makeMockSession())
        do {
            _ = try await svc.suggestOutfit(profileJSON: "{}", weatherJSON: "{}",
                                             inventoryJSON: "[]", historyJSON: "[]",
                                             occasion: "daily")
            XCTFail("Expected LLMError.parseError")
        } catch LLMError.parseError {
            // expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // ── LLMError descriptions ─────────────────────────────────────────────────

    func test_llmError_serverError_hasDescription() {
        XCTAssertNotNil(LLMError.serverError.errorDescription)
    }

    func test_llmError_emptyResponse_hasDescription() {
        XCTAssertNotNil(LLMError.emptyResponse.errorDescription)
    }

    func test_llmError_parseError_hasDescription() {
        XCTAssertNotNil(LLMError.parseError.errorDescription)
    }

    // ── Happy path: 200 with valid JSON returns text ──────────────────────────

    func test_generate_validResponse_returnsContent() async throws {
        let expected = "{\"season\":\"Spring\"}"
        MockURLProtocol.requestHandler = { request in
            let body = choicesEnvelope(expected)
            return try openRouterResponse(statusCode: 200, body: body)
        }
        let svc = GeminiService(session: makeMockSession())
        let result = try await svc.generate(prompt: "test")
        XCTAssertEqual(result, expected)
    }
}
