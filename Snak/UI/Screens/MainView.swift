import CoreLocation
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
    @State private var submitted = false

    @State private var list = PaginatedList()
    @State private var history = HistoryManager()
    @State private var discovery = DiscoveryFeed()

    @State private var mode: WikidataType = .item

    var body: some View {
        NavigationStack(path: $navigation) {
            Group {
                #if os(iOS)
                    iosLayout
                #elseif os(watchOS)
                    watchLayout
                #endif
            }
            .navigationTitle("Home")
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
            .navigationDestination(for: MapDestination.self) { dest in
                MapView(dest: dest)
            }
            .navigationDestination(for: ImageDestination.self) { dest in
                ImageView(dest: dest)
            }

            #if !os(watchOS)
                .searchable(text: $query, placement: .navigationBarDrawer, prompt: "Search...")
                .searchScopes($mode) {
                    Text(String(localized: "Items")).tag(WikidataType.item)
                    Text(String(localized: "Properties")).tag(WikidataType.property)
                }
                .onSubmit(of: .search, onSubmit)
                .onChange(of: query) { _, newValue in
                    if newValue.isEmpty {
                        onClear()
                    }
                }
            #endif

            .onChange(of: mode) { _, _ in
                onSubmit()
            }

            #if DEBUG
                .enableInjection()
                .onChange(of: navigation) {
                    navigation.save()
                }
            #endif

        }
        .environment(\.navigate, { navigation.append($0) })
    }

    private func onClear() {
        submitted = false
        query = ""
        list.cancel()
    }

    private func onSubmit() {
        guard !query.isEmpty else { return }
        submitted = true
        list.loadInitial { offset in
            try await searchWikidata(query: query, type: mode, offset: offset)
        }
    }

    @ViewBuilder private var watchLayout: some View {
        List {
            SearchBar(
                query: $query,
                prompt: "Search...",
                style: .search($mode),
                onSubmit: onSubmit,
                onClear: onClear
            )
            if submitted {
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
            if submitted {
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
