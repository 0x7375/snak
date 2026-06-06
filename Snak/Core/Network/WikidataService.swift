import Foundation

actor EntityCache {
    static let shared = EntityCache()

    private var storage: [String: Entity] = [:]
    private var order: [String] = []
    private let capacity = 20

    func get(_ id: String) -> Entity? {
        return storage[id]
    }

    func insert(_ entity: Entity) {
        if let index = order.firstIndex(of: entity.id) {
            order.remove(at: index)
        }

        order.append(entity.id)
        storage[entity.id] = entity

        if order.count > capacity {
            storage.removeValue(forKey: order.removeFirst())
        }
    }
}

extension WikidataType {
    var plural: String {
        switch self {
        case .item: return "items"
        case .property: return "properties"
        }
    }
}

func searchWikidata(query: String, type: WikidataType, offset: Int = 0, limit: Int = 15)
    async throws
    -> [Entity.Context]
{
    let response: SearchResponse = try await WikimediaEndpoint(
        queryItems: [
            URLQueryItem(name: "action", value: "wbsearchentities"),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "type", value: type.rawValue),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "language", value: systemLang),
            URLQueryItem(name: "uselang", value: systemLang),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "continue", value: "\(offset)"),
        ]
    ).fetch()

    return response.search.map {
        Entity.Context(id: $0.id, label: $0.label, description: $0.description)
    }
}

func fetchEntityContexts(ids: [String]) async throws -> [Entity.Context] {
    let response: ContextResponse = try await WikimediaEndpoint(
        queryItems: [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: ids.joined(separator: "|")),
            URLQueryItem(name: "props", value: "descriptions|labels"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "languages", value: systemLang),
            URLQueryItem(name: "uselang", value: systemLang),
        ]
    ).fetch()

    return response.entities.values.map {
        Entity.Context(
            id: $0.id,
            label: $0.labels.preferredLanguage()?.value,
            description: $0.descriptions.preferredLanguage()?.value
        )
    }
}

func fetchEntity(entityID: String, type: WikidataType) async throws
    -> Entity
{
    if let cached = await EntityCache.shared.get(entityID) {
        return cached
    }

    let response: EntityResponse = try await WikimediaEndpoint(
        queryItems: [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: entityID),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "languages", value: systemLang),
        ]
    ).fetch()

    guard let entity = response.entities[entityID] else {
        throw URLError(.badServerResponse)
    }

    let statements = try await fetchStatements(entity.claims, type)

    let fetched = Entity(
        id: entity.id,
        type: type,
        label: entity.labels.preferredLanguage()?.value,
        description: entity.descriptions.preferredLanguage()?.value,
        statements: statements
    )

    await EntityCache.shared.insert(fetched)
    return fetched
}

func fetchRandomItems(amount: Int = 4) async throws -> [Entity.Context] {
    let response: WikipediaRandomResponse = try await WikimediaEndpoint(
        host: "\(systemLang).wikipedia.org",
        queryItems: [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "generator", value: "random"),
            URLQueryItem(name: "grnnamespace", value: "0"),
            URLQueryItem(name: "grnlimit", value: String(amount)),
            URLQueryItem(name: "prop", value: "pageprops"),
            URLQueryItem(name: "ppprop", value: "wikibase_item"),
            URLQueryItem(name: "format", value: "json"),
        ]
    ).fetch()

    return response.query.pages.values.map {
        Entity.Context(id: $0.pageprops.wikibaseItem, label: nil, description: nil)
    }
}

func fetchFormatterURL(propertyID: String) async -> String? {
    let formatterPropertyID = "P1630"

    let response: FormatterResponse? = try? await WikimediaEndpoint(
        queryItems: [
            URLQueryItem(name: "action", value: "wbgetclaims"),
            URLQueryItem(name: "entity", value: propertyID),
            URLQueryItem(name: "property", value: formatterPropertyID),
            URLQueryItem(name: "format", value: "json"),
        ]
    ).fetch()

    guard let resultStatements = response?.claims[formatterPropertyID],
        let best = resultStatements.max(by: { $0.rank.priority < $1.rank.priority }),
        case .string(let formatter) = best.value
    else {
        return nil
    }

    return formatter
}

private func fetchStatements(_ claims: [String: [EntityResponse.Statement]], _ type: WikidataType)
    async throws
    -> [Entity
    .Statement]
{
    let properties = claims.keys
    let prefetchedLabels = try await prefetchLabels(Array(properties))

    return await withTaskGroup(of: Entity.Statement?.self) { group in
        for propertyID in properties {
            group.addTask {
                guard
                    let resultStatements = claims[propertyID],
                    let best = resultStatements.max(by: { $0.rank.priority < $1.rank.priority }),
                    let value = best.value
                else { return nil }

                return Entity.Statement(
                    property: .init(id: propertyID, label: prefetchedLabels[propertyID]),
                    value: await resolve(value)
                )
            }
        }

        var statements: [Entity.Statement] = []

        for await statement in group {
            if let statement {
                statements.append(statement)
            }
        }

        return statements.sorted {
            let num1 = Int($0.property.id.dropFirst()) ?? Int.max
            let num2 = Int($1.property.id.dropFirst()) ?? Int.max
            return num1 < num2
        }
    }
}

extension Collection {
    public func chunked(into size: Int) -> [SubSequence] {
        var chunks: [SubSequence] = []
        var rest = self[...]
        while !rest.isEmpty {
            chunks.append(rest.prefix(size))
            rest = rest.dropFirst(size)
        }
        return chunks
    }
}

private func prefetchLabels(_ properties: [String]) async throws -> [String: String] {
    return try await withThrowingTaskGroup(of: [Entity.Context].self) { group in
        for chunk in properties.chunked(into: 50) {
            group.addTask {
                return try await fetchEntityContexts(ids: Array(chunk))
            }
        }

        var labels: [String: String] = [:]
        for try await contexts in group {
            for ctx in contexts {
                if let label = ctx.label {
                    labels[ctx.id] = label
                }
            }
        }
        return labels
    }
}

private func resolve(_ value: WikidataValue<String>) async -> WikidataValue<
    Entity.Statement.Reference
> {
    switch value {
    case .entity(let id):
        let ctx = try? await fetchEntityContexts(ids: [id]).first
        return .entity(.init(id: id, label: ctx?.label))

    case .quantity(let amount, nil):
        return .quantity(amount: amount, unit: nil)

    case .quantity(let amount, let unitID?):
        let ctx = try? await fetchEntityContexts(ids: [unitID]).first
        return .quantity(amount: amount, unit: .init(id: unitID, label: ctx?.label))

    case .string(let s):
        return .string(s)

    case .time(let t, let p):
        return .time(time: t, precision: p)

    case .coordinate(let lat, let lon, let p):
        return .coordinate(lat: lat, lon: lon, precision: p)

    case .math(let f):
        return .math(f)

    case .url(let url):
        return .url(url)

    case .externalID(let id):
        return .externalID(id)

    case .media(let file):
        return .media(file)
    }
}
