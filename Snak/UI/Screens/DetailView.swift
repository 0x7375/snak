import SwiftUI

extension Entity.Statement {
    func matches(_ query: String) -> Bool {
        let fields = [property.label, property.id, value.displayString, value.id]
        return fields.contains { $0?.localizedCaseInsensitiveContains(query) == true }
    }
}

struct DetailView: View {
    let initialData: Entity.Context

    @State private var isLoading = false
    @State private var entity: Entity?
    @State private var searchText = ""

    var filteredStatements: [Entity.Statement] {
        let stmts = entity?.statements ?? []
        guard !searchText.isEmpty else { return stmts }
        return stmts.filter { $0.matches(searchText) }
    }

    var body: some View {
        List {
            let safeLabel = entity?.label ?? initialData.label
            let canShowGeneral = safeLabel != nil || !isLoading

            Section("Général") {
                if !canShowGeneral {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                } else {
                    if let safeLabel = entity?.label ?? initialData.label {
                        DetailRow(title: "Label", value: safeLabel, image: "tag")
                    }

                    let isItem = WikidataType(initialData.id) == .item
                    DetailRow(
                        title: "Type", value: isItem ? "Item" : "Propriété", image: "cube.box")

                    DetailRow(title: "ID", value: initialData.id, image: "barcode")

                    if let safeDesc = entity?.description ?? initialData.description {
                        DetailRow(title: "Description", value: safeDesc, image: "info.circle")
                    }
                }
            }

            if canShowGeneral && isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } else if !filteredStatements.isEmpty {
                Section("Déclarations") {
                    ForEach(filteredStatements, id: \.property.id) { stmt in
                        statementRow(stmt)
                    }
                }
            }
        }
        .navigationTitle("Détails")
        .task {
            guard entity == nil else { return }
            isLoading = true
            entity = try? await fetchEntity(
                entityID: initialData.id, type: WikidataType(initialData.id))
            isLoading = false
        }
        .searchable(text: $searchText, prompt: "Filter statements")
    }

    @ViewBuilder private func statementRow(_ stmt: Entity.Statement) -> some View {
        let safeLabel = stmt.property.label ?? stmt.property.id
        Group {
            if case .entity(let ref) = stmt.value {
                NavigationLink(
                    value: Entity.Context(id: ref.id, label: ref.label, description: nil)
                ) {
                    DetailRow(
                        title: safeLabel, value: stmt.value.displayString,
                        image: stmt.value.systemImage, id: ref.id)
                }
            } else {
                DetailRow(
                    title: safeLabel, value: stmt.value.displayString, image: stmt.value.systemImage
                )
            }
        }
        .swipeActions(edge: .leading) {
            NavigationLink(
                value: Entity.Context(
                    id: stmt.property.id, label: stmt.property.label, description: nil)
            ) {
                Label("Propriété", systemImage: "text.book.closed")
                    .tint(Color.strongOrange)
            }
        }
        .swipeActions {
            NavigationLink(value: StatementQuery(property: stmt.property, value: stmt.value)) {
                Label("Similaires", systemImage: "sparkle.magnifyingglass")
                    .tint(stmt.value.isSearchable ? .accentColor : .gray.opacity(0.1))
            }
            .disabled(!stmt.value.isSearchable)
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let image: String
    var id: String? = nil
    @State private var expand = false

    var body: some View {
        if let id = id {
            HStack {
                stack
                    #if os(iOS)
                        .layoutPriority(1)
                    #endif
                Spacer()
                EntityTypeCapsule(id: id)
            }
        } else {
            stack.onTapGesture {
                expand.toggle()
            }
        }
    }

    private var stack: some View {
        VStack(alignment: .leading, spacing: .small) {
            HStack(spacing: .small) {
                Image(systemName: image)
                Text(title)
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            Text(value)
                .lineLimit(expand ? nil : 2)
        }
        #if os(iOS)
            .contextMenu {
                Button {
                    UIPasteboard.general.string = value
                } label: {
                    Label("Copy", systemImage: "document.on.document")
                }
            }
        #endif
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()

    let mockContext = Entity.Context(
        id: "Q279446",
        label: nil,
        description: nil
    )
    NavigationStack(path: $path) {
        DetailView(initialData: mockContext)
            .navigationDestination(for: Entity.Context.self) { result in
                DetailView(initialData: result)
            }
            .navigationDestination(for: StatementQuery.self) { query in
                SimilarItemsView(query: query)
            }
    }
}
