import Foundation

let sparqlResultsLimit = 5000

struct SimilarItemsQuery {
    let propertyID: String
    let value: WikidataValue<Entity.Statement.Reference>
    var excludingEntityID: String? = nil
    var geoRadius: Double = 1
    var offset: Int = 0
    var limit: Int = 10
}

func findSimilarItems(_ query: SimilarItemsQuery) async throws -> [Entity.Context] {
    let filterClause =
        query.excludingEntityID
        .map { "FILTER(?item != wd:\($0))" } ?? ""
    let sparlQuery: String

    // find items in a radius
    if case .coordinate = query.value {
        sparlQuery = """
            SELECT ?item ?itemLabel ?itemDescription WHERE {
              {
                SELECT ?item ?distance WHERE {
                  SERVICE wikibase:around {
                    ?item wdt:\(query.propertyID) ?location.
                    bd:serviceParam wikibase:center \(query.value.sparqlFormat) .
                    bd:serviceParam wikibase:radius "\(query.geoRadius)" .
                    bd:serviceParam wikibase:distance ?distance .
                  }
                  \(filterClause)
                }
                ORDER BY ?distance
                LIMIT \(query.limit)
                OFFSET \(query.offset)
              }
              SERVICE wikibase:label { bd:serviceParam wikibase:language "\(systemLang),en". }
            }
            """
    } else {
        let itemFilter: String

        switch query.value {
        case .time(let time, let precision):
            itemFilter = """
                ?item p:\(query.propertyID) ?statement .
                ?statement psv:\(query.propertyID) ?stmtValue .
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
                ?item wdt:\(query.propertyID) ?valAmount .

                ?item p:\(query.propertyID) ?stmt .
                ?stmt psv:\(query.propertyID) ?stmtValue .
                ?stmtValue wikibase:quantityUnit \(safeUnit) .

                FILTER(?valAmount >= \(lowerBound) && ?valAmount <= \(upperBound))
                """

        default:
            itemFilter = """
                ?item wdt:\(query.propertyID) \(query.value.sparqlFormat) .
                """
        }

        let finalFilter = """
                \(itemFilter)
                \(filterClause)
            """

        sparlQuery = popularityOrderedQuery(
            itemFilter: finalFilter, limit: query.limit, offset: query.offset)
    }

    let response: SPARQLResponse = try await WikimediaEndpoint(
        host: "query.wikidata.org",
        path: "/sparql",
        queryItems: [
            URLQueryItem(name: "query", value: sparlQuery),
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

private func popularityOrderedQuery(itemFilter: String, limit: Int, offset: Int)
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
