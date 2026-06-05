import Foundation

struct EntityResponse: Decodable {
    let entities: [String: EntityData]

    struct EntityData: Decodable {
        let id: String
        let labels: [String: Language]
        let descriptions: [String: Language]
        let claims: [String: [Statement]]

        struct Language: Decodable {
            let value: String
        }
    }

    struct Statement: Decodable {
        let rank: Rank
        let value: WikidataValue<String>?

        enum Rank: String, Decodable {
            case preferred
            case normal
            case deprecated
            nonisolated var priority: Int {
                switch self {
                case .deprecated: 0
                case .normal: 1
                case .preferred: 2
                }
            }
        }

        private enum DataType: Decodable {
            case string
            case item, property
            case quantity
            case math
            case time
            case coordinate
            case url
            case externalID
            case other

            init(from decoder: Decoder) throws {
                let decoded = try decoder.singleValueContainer().decode(String.self)
                switch decoded {
                case "string": self = .string
                case "quantity": self = .quantity
                case "time": self = .time
                case "math": self = .math
                case "wikibase-item": self = .item
                case "wikibase-property": self = .property
                case "globe-coordinate": self = .coordinate
                case "url": self = .url
                case "external-id": self = .externalID
                default: self = .other
                }
            }
        }

        struct EntityValue: Decodable {
            let id: String
        }

        struct Time: Decodable {
            let time: String
            let precision: WikidataPrecision
        }

        struct Coord: Decodable {
            let latitude: Double
            let longitude: Double
            let precision: Double
        }

        struct Quantity: Decodable {
            let amount: String
            let unit: String
        }

        enum CodingKeys: String, CodingKey { case rank, mainsnak }
        enum SnakKeys: String, CodingKey { case datatype, datavalue }
        enum DataValueKeys: String, CodingKey { case value }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            rank = try container.decode(Rank.self, forKey: .rank)

            let mainsnak = try container.nestedContainer(keyedBy: SnakKeys.self, forKey: .mainsnak)
            let dataType = try? mainsnak.decode(DataType.self, forKey: .datatype)
            let datavalue = try? mainsnak.nestedContainer(
                keyedBy: DataValueKeys.self, forKey: .datavalue)

            value = Statement.decodeValue(from: datavalue, dataType: dataType)
        }

        private static func decodeValue(
            from vc: KeyedDecodingContainer<DataValueKeys>?, dataType: DataType?
        ) -> WikidataValue<String>? {
            switch dataType {
            case .item, .property:
                guard let ev = try? vc?.decode(EntityValue.self, forKey: .value) else { return nil }
                return .entity(ev.id)

            case .math:
                guard let f = try? vc?.decode(String.self, forKey: .value) else { return nil }
                return .math(f)

            case .time:
                guard let t = try? vc?.decode(Time.self, forKey: .value) else { return nil }
                return .time(
                    time: t.time.trimmingCharacters(in: .init(charactersIn: "+")),
                    precision: t.precision)

            case .coordinate:
                guard let coord = try? vc?.decode(Coord.self, forKey: .value) else { return nil }
                return .coordinate(
                    lat: coord.latitude, lon: coord.longitude, precision: coord.precision)

            case .quantity:
                guard let q = try? vc?.decode(Quantity.self, forKey: .value) else { return nil }
                let amount = Double(q.amount.trimmingCharacters(in: .init(charactersIn: "+"))) ?? 0
                let unitID = q.unit == "1" ? nil : URL(string: q.unit)?.lastPathComponent
                return .quantity(amount: amount, unit: unitID)

            case .url:
                guard let url = try? vc?.decode(String.self, forKey: .value) else { return nil }
                return .url(url)

            case .externalID:
                guard let id = try? vc?.decode(String.self, forKey: .value) else { return nil }
                return .externalID(id)

            default:
                guard let str = try? vc?.decode(String.self, forKey: .value) else { return nil }
                return .string(str)
            }
        }

    }
}

struct SearchResponse: Decodable {
    let search: [Result]

    struct Result: Decodable {
        let id: String
        let label: String?
        let description: String?
    }
}

struct ContextResponse: Decodable {
    let entities: [String: Context]

    struct Context: Decodable {
        let id: String
        let labels: [String: Language]
        let descriptions: [String: Language]

        struct Language: Decodable {
            let value: String
        }
    }
}

struct WikipediaRandomResponse: Decodable {
    let query: Query

    struct Query: Decodable {
        let pages: [String: Page]

        struct Page: Decodable {
            let pageprops: PageProps

            struct PageProps: Decodable {
                let wikibaseItem: String

                enum CodingKeys: String, CodingKey {
                    case wikibaseItem = "wikibase_item"
                }
            }
        }
    }
}

struct SPARQLResponse: Decodable {
    let results: Results

    struct Results: Decodable {
        let bindings: [Binding]

        struct Binding: Decodable {
            let item: Value?
            let itemLabel: Value?
            let itemDescription: Value?

            struct Value: Decodable {
                let value: String
            }
        }
    }
}
