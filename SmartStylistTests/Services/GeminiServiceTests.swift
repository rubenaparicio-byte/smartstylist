import XCTest
@testable import SmartStylist

final class GeminiServiceTests: XCTestCase {

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
}
