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

    static func == (lhs: StatementQuery, rhs: StatementQuery) -> Bool {
        return lhs.property.id == rhs.property.id
            && lhs.value.sparqlFormat == rhs.value.sparqlFormat
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(property.id)
        hasher.combine(value.sparqlFormat)
    }
}

enum WikidataType: String {
    case item
    case property

    init(_ id: String) {
        self = id.hasPrefix("P") ? .property : .item
    }
}

enum WikidataValue<Ref> {
    case string(String)
    case math(String)
    case entity(Ref)
    case quantity(amount: Double, unit: Ref?)
    case time(time: String, precision: Int)
    case coordinate(lat: Double, lon: Double)
    case url(String)
    case externalID(String)
}

extension WikidataValue: Codable where Ref: Codable {}
