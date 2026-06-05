import SwiftUI

struct SimilarItemsView: View {
    let query: StatementQuery
    @State private var list = PaginatedList()

    var body: some View {
        Group {
            List {
                PaginatedListView(model: list)
            }
            #if os(watchOS)
                .listSectionSpacing(.medium)
            #endif
        }
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(query.property.label?.firstUppercased ?? query.property.id)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Text(query.value.displayString)
                        .font(.headline)
                    }
                }
            }
        #elseif os(watchOS)
            .navigationTitle(query.value.displayString)
        #endif
        .task {
            list.loadInitial { offset in
                try await findSimilarItems(
                    SimilarItemsQuery(
                        propertyID: query.property.id,
                        value: query.value,
                        excludingEntityID: query.entityID,
                        offset: offset
                    ))
            }
        }
    }
}
