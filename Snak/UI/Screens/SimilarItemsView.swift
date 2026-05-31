import SwiftUI

struct SimilarItemsView: View {
    let query: StatementQuery
    @State private var list = PaginatedList()

    var body: some View {
        Group {
            List {
                headerView
                    #if os(iOS)
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                        .padding(.horizontal, .medium)
                        .padding(.vertical, .small)
                    #endif

                PaginatedListView(model: list)
            }
            #if os(watchOS)
                .listSectionSpacing(.medium)
            #endif
        }
        .navigationTitle("Similar")
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

    private var headerView: some View {
        let propertyText = Text(query.property.label ?? query.property.id).bold()
        let valueText = Text(query.value.displayString).foregroundStyle(.secondary)

        let type = WikidataType(query.value.id ?? "Q")

        return HStack(alignment: .firstTextBaseline) {
            Image(systemName: query.value.systemImage)
                .foregroundStyle(type.displayColor)

            Text("\(propertyText): \(valueText)")
                .lineLimit(3)
        }
        .listRowBackground(Color.clear)
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
