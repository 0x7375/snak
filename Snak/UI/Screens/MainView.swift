import SwiftUI

#if DEBUG
    @_exported import HotSwiftUI
#endif

struct MainView: View {
    #if DEBUG
        @ObserveInjection var injection
    #endif

    #if DEBUG
        @State private var navigation = NavigationPath.restore()
    #else
        @State private var navigation = NavigationPath()
    #endif
    @State private var query = ""
    @State private var showResults = false

    @State private var list = PaginatedList()
    @State private var history = HistoryManager()
    @State private var discovery = DiscoveryFeed()

    var body: some View {
        NavigationStack(path: $navigation) {
            Group {
                #if os(iOS)
                    iosLayout
                #else
                    watchLayout
                #endif
            }
            .navigationTitle("Snak")
            .navigationDestination(for: Entity.Context.self) { ctx in
                DetailView(initialData: ctx)
                    .task {
                        try? await Task.sleep(for: .seconds(1))
                        guard !Task.isCancelled else { return }
                        history.add(ctx)
                    }
            }
            .navigationDestination(for: StatementQuery.self) { query in
                SimilarItemsView(query: query)
            }
            .environment(\.navigate, { navigation.append($0) })

            #if os(iOS)
                .searchable(text: $query, placement: .navigationBarDrawer, prompt: "Search...")
                .onSubmit(of: .search, onSubmit)
                .onChange(of: query) { _, newValue in
                    if newValue.isEmpty {
                        onClear()
                    }
                }
            #endif

            #if DEBUG
                .enableInjection()
                .onChange(of: navigation) {
                    navigation.save()
                }
            #endif

        }
    }

    private func onClear() {
        showResults = false
        query = ""
        list.cancel()
    }

    private func onSubmit() {
        guard !query.isEmpty else { return }
        showResults = true
        list.loadInitial { offset in
            try await searchWikidata(query: query, offset: offset)
        }
    }

    @ViewBuilder private var watchLayout: some View {
        List {
            SearchBar(
                query: $query, onSubmit: onSubmit, onClear: onClear, resultsShown: showResults
            )
            if showResults {
                PaginatedListView(model: list)
            } else {
                FetchRandomItemButton()
                    .listRowBackground(Color.clear)
            }
        }
        .listSectionSpacing(.medium)
    }

    @ViewBuilder private var iosLayout: some View {
        VStack {
            if showResults {
                List {
                    PaginatedListView(model: list)
                }
                .listSectionSpacing(.small)
            } else {
                ScrollView {
                    VStack(spacing: .extraLarge) {
                        if !history.visited.isEmpty {
                            recentHistorySection
                        }
                        discoverySection
                    }
                    .padding(.vertical, .medium)
                }
            }
        }
        .task {
            if discovery.items.isEmpty {
                await discovery.load()
            }
        }
    }

    @ViewBuilder private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: .medium) {
            Text("Recently visited")
                .font(.headline)
                .padding(.horizontal, .large)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .medium) {
                    ForEach(history.visited, id: \.id) { item in
                        RecentlyVisitedCard(item: item)
                    }
                }
                .padding(.horizontal, .large)
            }
        }
    }

    @ViewBuilder private var discoverySection: some View {
        VStack(spacing: .medium) {
            HStack {
                Text("Discover")
                    .font(.headline)

                Spacer()

                Button {
                    Task { await discovery.load() }
                } label: {
                    ZStack {
                        ProgressView()
                            .opacity(discovery.isFetching ? 1 : 0)

                        Image(systemName: "dice.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                            .opacity(discovery.isFetching ? 0 : 1)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, .large)

            VStack(spacing: .medium) {
                ForEach(discovery.items, id: \.id) { item in
                    SearchResultRow(result: item)
                        .padding(.medium)
                        .background(
                            Color.secondary.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                }
            }
            .padding(.horizontal, .large)
        }
    }
}

#Preview {
    MainView()
}
