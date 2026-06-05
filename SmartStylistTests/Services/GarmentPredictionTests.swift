import XCTest
@testable import SmartStylist

final class GarmentPredictionTests: XCTestCase {

    func test_garmentPrediction_decodesCorrectly() throws {
        let json = """
        {
          "category": "superior",
          "primaryColor": "#2C3E50",
          "pattern": "Solid",
          "style": "Casual",
          "tags": ["weekend", "brunch"]
        }
        """.data(using: .utf8)!

        let prediction = try JSONDecoder().decode(GarmentPrediction.self, from: json)
        XCTAssertEqual(prediction.category, "superior")
        XCTAssertEqual(prediction.primaryColor, "#2C3E50")
        XCTAssertEqual(prediction.pattern, "Solid")
        XCTAssertEqual(prediction.style, "Casual")
        XCTAssertEqual(prediction.tags, ["weekend", "brunch"])
    }

    func test_garmentPrediction_emptyTagsDecodes() throws {
        let json = """
        {
          "category": "calzado",
          "primaryColor": "#000000",
          "pattern": "Solid",
          "style": "Formal",
          "tags": []
        }
        """.data(using: .utf8)!

        let prediction = try JSONDecoder().decode(GarmentPrediction.self, from: json)
        XCTAssertTrue(prediction.tags.isEmpty)
        XCTAssertEqual(prediction.category, "calzado")
    }

    func test_bulkScanResult_decodesMultipleItems() throws {
        let json = """
        {
          "items": [
            {
              "category": "superior",
              "primaryColor": "#FFFFFF",
              "pattern": "Solid",
              "style": "Casual",
              "tags": ["everyday"]
            },
            {
              "category": "inferior",
              "primaryColor": "#1A1A2E",
              "pattern": "Solid",
              "style": "Smart Casual",
              "tags": ["office", "dinner"]
            }
          ]
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(BulkScanResult.self, from: json)
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.items[0].category, "superior")
        XCTAssertEqual(result.items[1].category, "inferior")
        XCTAssertEqual(result.items[1].tags, ["office", "dinner"])
    }

    func test_bulkScanResult_emptyItemsArray() throws {
        let json = """
        { "items": [] }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(BulkScanResult.self, from: json)
        XCTAssertTrue(result.items.isEmpty)
    }

    func test_garmentPrediction_categoryMapsToClothingCategory() throws {
        let json = """
        {
          "category": "abrigo",
          "primaryColor": "#8B6914",
          "pattern": "Checks",
          "style": "Smart Casual",
          "tags": ["autumn", "layering"]
        }
        """.data(using: .utf8)!

        let prediction = try JSONDecoder().decode(GarmentPrediction.self, from: json)
        let category = ClothingCategory(rawValue: prediction.category)
        XCTAssertEqual(category, .outerwear)
    }
}
