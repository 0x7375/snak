import Foundation

let sparqlResultsLimit = 5000

func findSimilarItems(
    propertyID: String, value: WikidataValue<Entity.Statement.Reference>, offset: Int = 0,
    limit: Int = 10
) async throws -> [Entity.Context] {
    let query: String

    // find items in a 1km radius
    if case .coordinate = value {
        query = """
            SELECT ?item ?itemLabel ?itemDescription WHERE {
              {
                SELECT ?item ?distance WHERE {
                  SERVICE wikibase:around {
                    ?item wdt:\(propertyID) ?location.
                    bd:serviceParam wikibase:center \(value.sparqlFormat) .
                    bd:serviceParam wikibase:radius "1" .
                    bd:serviceParam wikibase:distance ?distance .
                  }
                }
                ORDER BY ?distance
                LIMIT \(limit)
                OFFSET \(offset)
              }
              SERVICE wikibase:label { bd:serviceParam wikibase:language "\(systemLang),en". }
            }
            """
    } else {
        query = """
            SELECT ?item ?itemLabel ?itemDescription WHERE {
              {
                SELECT ?item ?popularity WHERE {
                  {
                    SELECT ?item WHERE {
                      ?item wdt:\(propertyID) \(value.sparqlFormat) .
                    }
                    LIMIT \(sparqlResultsLimit)
                  }
                  OPTIONAL { ?item wikibase:sitelinks ?popularity . }
                }
                ORDER BY DESC(?popularity)
                LIMIT \(limit)
                OFFSET \(offset)
              }
              SERVICE wikibase:label { bd:serviceParam wikibase:language "\(systemLang),en". }
            }
            """
    }

    let response: SPARQLResponse = try await WikimediaEndpoint(
        host: "query.wikidata.org",
        path: "/sparql",
        queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "format", value: "json"),
        ]
    ).fetch()

    return response.results.bindings.map {
        Entity.Context(
            id: URL(string: $0.item?.value ?? "")?.lastPathComponent ?? "",
            label: $0.itemLabel?.value,
            description: $0.itemDescription?.value
        )
    }
}

extension WikidataValue where Ref == Entity.Statement.Reference {
    var sparqlFormat: String {
        switch self {
        case .entity(let reference):
            return "wd:\(reference.id)"
        case .string(let text), .externalID(let text):
            return "\"\(text)\""
        case .quantity(let amount, _):
            return "\"\(String(amount))\"^^xsd:decimal"
        case .time(let date, _):
            return "\"\(date)\"^^xsd:dateTime"
        case .coordinate(let lat, let lon):
            return "\"Point(\(lon) \(lat))\"^^geo:wktLiteral"
        case .url(let url):
            return "<\(url)>"
        default:
            return ""
        }
    }
}
