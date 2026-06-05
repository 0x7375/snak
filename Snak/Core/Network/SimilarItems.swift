import Foundation

let sparqlResultsLimit = 5000

func findSimilarItems(
    propertyID: String, entityID: String, value: WikidataValue<Entity.Statement.Reference>,
    offset: Int = 0,
    limit: Int = 10
) async throws -> [Entity.Context] {
    let filterString = "FILTER(?item != wd:\(entityID))"
    let geoRadius = 1
    let query: String

    // find items in a radius
    if case .coordinate = value {
        query = """
            SELECT ?item ?itemLabel ?itemDescription WHERE {
              {
                SELECT ?item ?distance WHERE {
                  SERVICE wikibase:around {
                    ?item wdt:\(propertyID) ?location.
                    bd:serviceParam wikibase:center \(value.sparqlFormat) .
                    bd:serviceParam wikibase:radius "\(geoRadius)" .
                    bd:serviceParam wikibase:distance ?distance .
                    \(filterString)
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
        let itemFilter: String

        switch value {
        case .time(let time, let precision):
            itemFilter = """
                ?item p:\(propertyID) ?statement .
                ?statement psv:\(propertyID) ?stmtValue .
                ?statement a wikibase:BestRank .

                ?stmtValue wikibase:timeValue "\(time)"^^xsd:dateTime .
                ?stmtValue wikibase:timePrecision \(precision) .
                """

        case .quantity(let amount, let unit):
            let safeUnit = unit.map { "wd:\($0.id)" } ?? "wd:Q199"

            let range = abs(amount * 0.1)
            let lowerBound = amount - range
            let upperBound = amount + range

            itemFilter = """
                ?item wdt:\(propertyID) ?valAmount .

                ?item p:\(propertyID) ?stmt .
                ?stmt psv:\(propertyID) ?stmtValue .
                ?stmtValue wikibase:quantityUnit \(safeUnit) .

                FILTER(?valAmount >= \(lowerBound) && ?valAmount <= \(upperBound))
                """

        default:
            itemFilter = """
                ?item wdt:\(propertyID) \(value.sparqlFormat) .
                """
        }

        let finalFilter = """
                \(itemFilter)
                \(filterString)
            """

        query = popularityOrderedQuery(
            itemFilter: finalFilter, initialID: entityID, limit: limit, offset: offset)
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

private func popularityOrderedQuery(itemFilter: String, initialID: String, limit: Int, offset: Int)
    -> String
{
    """
    SELECT ?item ?itemLabel ?itemDescription WHERE {
      {
        SELECT ?item ?popularity WHERE {
          {
            SELECT DISTINCT ?item WHERE {
              \(itemFilter)
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

extension WikidataValue where Ref == Entity.Statement.Reference {
    var sparqlFormat: String {
        switch self {
        case .entity(let reference):
            return "wd:\(reference.id)"
        case .string(let text), .externalID(let text):
            return "\"\(text)\""
        case .coordinate(let lat, let lon, _):
            return "\"Point(\(lon) \(lat))\"^^geo:wktLiteral"
        case .url(let url):
            return "<\(url)>"
        default:
            return ""
        }
    }
}
