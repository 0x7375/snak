import SwiftUI

struct PaginatedListView: View {
    let model: PaginatedList

    var body: some View {
        if model.isLoading && model.results.isEmpty {
            LoadingView()
                .id(UUID())
        } else if model.results.isEmpty {
            NoResultFoundLabel()
        } else {
            Section {
                ForEach(model.results, id: \.id) { result in
                    SearchResultRow(result: result)
                }
            } header: {
                Text("Résultats").font(.body)
            } footer: {
                if model.hasMore {
                    LoadingView()
                        .id(model.results.count)
                        .task { await model.loadMore() }
                        .padding(.top, .large)
                }
            }
        }
    }
}

struct NoResultFoundLabel: View {
    var body: some View {
        VStack(spacing: .medium) {
            Image(systemName: "exclamationmark.magnifyingglass")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("Aucun résultat trouvé")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .padding(.top, .large)
    }
}
