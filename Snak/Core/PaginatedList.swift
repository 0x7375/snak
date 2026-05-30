import Foundation

@Observable
@MainActor
class PaginatedList {
    var results: [Entity.Context] = []
    var isLoading = false
    var hasMore = true

    let limit: Int
    var fetcher: ((Int) async throws -> [Entity.Context])?
    var currentTask: Task<Void, Never>?

    init(limit: Int = 10) {
        self.limit = limit
    }

    func loadInitial(fetcher: @escaping (Int) async throws -> [Entity.Context]) {
        currentTask?.cancel()
        self.fetcher = fetcher
        results = []
        hasMore = true

        currentTask = Task { await execute() }
    }

    func loadMore() async {
        guard !isLoading, hasMore else { return }
        await execute()
    }

    private func execute() async {
        guard let fetcher else { return }

        isLoading = true
        defer { isLoading = false }

        let page = (try? await fetcher(results.count)) ?? []
        guard !Task.isCancelled else { return }
        results.append(contentsOf: page)

        hasMore = page.count >= limit
    }

    func cancel() {
        fetcher = nil
        currentTask?.cancel()
        results = []
        hasMore = true
        isLoading = false
    }
}
