import Foundation

@Observable
@MainActor
class HistoryManager {
    let storedKey = "RecentHistory"
    var visited: [Entity.Context] = []

    init() {
        load()
    }

    func add(_ ctx: Entity.Context) {
        visited.removeAll { $0.id == ctx.id }
        visited.insert(ctx, at: 0)

        if visited.count > 10 {
            visited.removeLast()
        }

        save()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(visited) {
            UserDefaults.standard.set(encoded, forKey: storedKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storedKey),
            let decoded = try? JSONDecoder().decode([Entity.Context].self, from: data)
        {
            visited = decoded
        }
    }
}
