import Foundation

struct StyleResponse: Codable {
    let climaProcesado: String
    let analisisContexto: String
    let outfitSugerido: OutfitSuggestion
    let consejoEstilo: String

    struct OutfitSuggestion: Codable {
        let superior: UUID?
        let inferior: UUID?
        let calzado: UUID?
        let abrigo: UUID?

        var allItemIds: [UUID] {
            [superior, inferior, calzado, abrigo].compactMap { $0 }
        }
    }

    enum CodingKeys: String, CodingKey {
        case climaProcesado   = "clima_procesado"
        case analisisContexto = "analisis_contexto"
        case outfitSugerido   = "outfit_sugerido"
        case consejoEstilo    = "consejo_estilo"
    }
}
