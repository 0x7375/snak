import Foundation

struct Entity {
    let id: String
    let type: WikidataType
    let label: String?
    let description: String?
    let statements: [Statement]

    struct Statement {
        let property: Property
        let value: WikidataValue<Reference>

        struct Reference: Codable, Hashable {
            let id: String
            let label: String?
        }
    }

    struct Property: Codable, Hashable {
        let id: String
        let label: String?
    }

    struct Context: Codable, Hashable {
        let id: String
        let label: String?
        let description: String?
    }
}

struct StatementQuery: Codable, Hashable {
    let property: Entity.Property
    let value: WikidataValue<Entity.Statement.Reference>
    let entityID: String

    static func == (lhs: StatementQuery, rhs: StatementQuery) -> Bool {
        return lhs.property.id == rhs.property.id
            && lhs.value.sparqlFormat == rhs.value.sparqlFormat
            && lhs.entityID == rhs.entityID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(property.id)
        hasher.combine(value.sparqlFormat)
        hasher.combine(entityID)
    }
}

enum WikidataType: String {
    case item
    case property

    init(_ id: String) {
        self = id.hasPrefix("P") ? .property : .item
    }
}

enum WikidataPrecision: Int, Codable {
    /// Wikidata time precision values
    /// https://www.wikidata.org/wiki/Help:Dates#Precision
    case millennium = 6
    case century = 7
    case decade = 8
    case year = 9
    case month = 10
    case day = 11
}

enum WikidataValue<Ref> {
    case string(String)
    case math(String)
    case entity(Ref)
    case quantity(amount: Double, unit: Ref?)
    case time(time: String, precision: WikidataPrecision)
    case coordinate(lat: Double, lon: Double, precision: Double)
    case url(String)
    case externalID(String)
    case media(String)
}

extension WikidataValue: Codable where Ref: Codable {}
