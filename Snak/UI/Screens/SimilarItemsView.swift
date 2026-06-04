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
                    propertyID: query.property.id,
                    value: query.value,
                    offset: offset
                )
            }
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()

    let mockProperty = Entity.Property(
        id: "P106",
        label: "occupation"
    )

    let mockReference = Entity.Statement.Reference(
        id: "Q82594",
        label: "computer scientist"
    )

    let mockQuery = StatementQuery(
        property: mockProperty,
        value: .entity(mockReference)
    )

    NavigationStack(path: $path) {
        SimilarItemsView(query: mockQuery)
            .navigationDestination(for: Entity.Context.self) { result in
                DetailView(initialData: result)
            }
            .navigationDestination(for: StatementQuery.self) { query in
                SimilarItemsView(query: query)
            }
    }
}
