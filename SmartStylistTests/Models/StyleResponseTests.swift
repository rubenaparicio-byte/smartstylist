import XCTest
@testable import SmartStylist

final class StyleResponseTests: XCTestCase {

    private let sampleJSON = """
    {
      "clima_procesado": "18°C, Cloudy",
      "analisis_contexto": "A muted overcast day calls for layered warmth.",
      "outfit_sugerido": {
        "superior_id": "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",
        "inferior_id": "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB",
        "calzado_id":  "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC",
        "abrigo_id":   null
      },
      "consejo_estilo": "Tuck your shirt for a cleaner silhouette."
    }
    """.data(using: .utf8)!

    // ── Decode ────────────────────────────────────────────────────────────────

    func test_decode_allFieldsPopulated() throws {
        let response = try JSONDecoder().decode(StyleResponse.self, from: sampleJSON)
        XCTAssertEqual(response.climaProcesado,   "18°C, Cloudy")
        XCTAssertEqual(response.consejoEstilo,    "Tuck your shirt for a cleaner silhouette.")
        XCTAssertEqual(response.outfitSugerido.allItemIds.count, 3)
        XCTAssertNil(response.outfitSugerido.abrigo)
    }

    func test_decode_nullFieldsAreNil() throws {
        let response = try JSONDecoder().decode(StyleResponse.self, from: sampleJSON)
        XCTAssertNil(response.outfitSugerido.abrigo)
    }

    // ── Encode → Decode roundtrip (UserDefaults cache) ────────────────────────

    func test_encodeDecodedRoundtrip_preservesAllFields() throws {
        let original  = try JSONDecoder().decode(StyleResponse.self, from: sampleJSON)
        let encoded   = try JSONEncoder().encode(original)
        let recovered = try JSONDecoder().decode(StyleResponse.self, from: encoded)
        XCTAssertEqual(recovered.climaProcesado,   original.climaProcesado)
        XCTAssertEqual(recovered.analisisContexto, original.analisisContexto)
        XCTAssertEqual(recovered.consejoEstilo,    original.consejoEstilo)
        XCTAssertEqual(recovered.outfitSugerido.superior, original.outfitSugerido.superior)
        XCTAssertEqual(recovered.outfitSugerido.inferior, original.outfitSugerido.inferior)
        XCTAssertEqual(recovered.outfitSugerido.calzado,  original.outfitSugerido.calzado)
        XCTAssertNil(recovered.outfitSugerido.abrigo)
    }

    func test_encodeDecodedRoundtrip_allNullIds() throws {
        let json = """
        {
          "clima_procesado":"No weather",
          "analisis_contexto":"Offline.",
          "outfit_sugerido":{"superior_id":null,"inferior_id":null,"calzado_id":null,"abrigo_id":null},
          "consejo_estilo":"Stay warm."
        }
        """.data(using: .utf8)!
        let original  = try JSONDecoder().decode(StyleResponse.self, from: json)
        let encoded   = try JSONEncoder().encode(original)
        let recovered = try JSONDecoder().decode(StyleResponse.self, from: encoded)
        XCTAssertTrue(recovered.outfitSugerido.allItemIds.isEmpty)
    }

    // ── allItemIds ────────────────────────────────────────────────────────────

    func test_allItemIds_countsOnlyNonNil() throws {
        let response = try JSONDecoder().decode(StyleResponse.self, from: sampleJSON)
        XCTAssertEqual(response.outfitSugerido.allItemIds.count, 3)
    }

    func test_allItemIds_emptyWhenAllNil() {
        let suggestion = StyleResponse.OutfitSuggestion(
            superior: nil, inferior: nil, calzado: nil, abrigo: nil
        )
        XCTAssertTrue(suggestion.allItemIds.isEmpty)
    }
}
