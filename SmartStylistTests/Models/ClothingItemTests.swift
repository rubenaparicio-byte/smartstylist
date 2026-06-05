import XCTest
@testable import SmartStylist

final class ClothingItemTests: XCTestCase {

    func test_itemStatus_disposedRawValue() {
        XCTAssertEqual(ItemStatus.disposed.rawValue, "disposed")
    }

    func test_itemStatus_allCasesCount() {
        XCTAssertEqual(ItemStatus.allCases.count, 3)
    }

    func test_clothingCategory_topRawValue() {
        XCTAssertEqual(ClothingCategory.top.rawValue, "superior")
    }

    func test_styleResponse_decodesCorrectly() throws {
        let json = """
        {
          "clima_procesado": "20°C, Sunny",
          "analisis_contexto": "A bright spring day calls for layered pastels.",
          "outfit_sugerido": {
            "superior": "00000000-0000-0000-0000-000000000001",
            "inferior": "00000000-0000-0000-0000-000000000002",
            "calzado":  "00000000-0000-0000-0000-000000000003",
            "abrigo":   null
          },
          "consejo_estilo": "Roll your sleeves — a casual touch on a tailored look."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StyleResponse.self, from: json)
        XCTAssertEqual(response.climaProcesado, "20°C, Sunny")
        XCTAssertNil(response.outfitSugerido.abrigo)
        XCTAssertEqual(response.outfitSugerido.allItemIds.count, 3)
    }

    func test_styleResponse_allItemIdsExcludesNil() throws {
        let suggestion = StyleResponse.OutfitSuggestion(
            superior: UUID(), inferior: UUID(), calzado: nil, abrigo: nil
        )
        XCTAssertEqual(suggestion.allItemIds.count, 2)
    }
}
