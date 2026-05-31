import Foundation

let discoveryItemCount = 4

@Observable
@MainActor
class DiscoveryFeed {
    var items: [Entity.Context] = []
    var isFetching = false

    func load() async {
        guard !isFetching else { return }

        items = []
        isFetching = true
        defer { isFetching = false }

        if let newItems = try? await fetchRandomItems(amount: discoveryItemCount) {
            items = (try? await fetchEntityContexts(ids: newItems.map { $0.id })) ?? []
        }
    }
}
