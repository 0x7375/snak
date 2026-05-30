import Foundation

@Observable
@MainActor
class DiscoveryFeed {
    var numberOfResults: Int = 4
    var items: [Entity.Context] = []
    var isFetching = false

    func load() async {
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }

        if let newItems = try? await fetchRandomItems(amount: 4) {
            items = (try? await fetchEntityContexts(ids: newItems.map { $0.id })) ?? []
        }
    }
}
