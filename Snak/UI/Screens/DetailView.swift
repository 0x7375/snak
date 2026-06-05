import MapKit
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

    var fallbackLabel: String? {
        return entity?.label ?? initialData.label
    }

    var body: some View {
        let canShowGeneral = fallbackLabel != nil || !isLoading

        List {
            Section("General") {
                if !canShowGeneral {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                } else {
                    if let fallbackLabel {
                        DetailRow(title: "Label", value: fallbackLabel, image: "tag")
                    }

                    let isItem = WikidataType(initialData.id) == .item
                    DetailRow(
                        title: "Type", value: isItem ? "Item" : "Property", image: "cube.box")

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
                Section("Statements") {
                    ForEach(filteredStatements, id: \.property.id) { stmt in
                        statementRow(stmt)
                    }
                }
            }
        }
        .navigationTitle(fallbackLabel ?? String(localized: "Details"))
        .task {
            guard entity == nil else { return }
            isLoading = true
            entity = try? await fetchEntity(
                entityID: initialData.id, type: WikidataType(initialData.id))
            isLoading = false
        }
        #if os(iOS)
            .searchable(text: $searchText, prompt: "Filter statements...")
        #endif
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
                        image: stmt.value.systemImage, style: .entity(id: ref.id))
                }
            } else if case .coordinate(let lat, let lon, let p) = stmt.value {
                NavigationLink(
                    value: MapDestination(
                        title: fallbackLabel ?? initialData.id, latitude: lat, longitude: lon,
                        precision: p)
                ) {
                    DetailRow(
                        title: safeLabel, value: stmt.value.displayString,
                        image: stmt.value.systemImage, style: .fixed)
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
                Label("Property", systemImage: "text.book.closed")
                    .tint(Color.strongOrange)
            }
        }
        .swipeActions {
            if stmt.value.isSearchable {
                NavigationLink(
                    value: StatementQuery(
                        property: stmt.property, value: stmt.value, entityID: initialData.id)
                ) {
                    Label("Similar", systemImage: "sparkle.magnifyingglass")
                        .tint(.accentColor)
                }
            }
        }
    }
}

struct DetailRow: View {
    enum Style {
        case expandable
        case fixed
        case entity(id: String)
    }

    let title: String
    let value: String
    let image: String
    var style: Style = .expandable
    @State private var expand = false

    var body: some View {
        switch style {
        case .entity(let id):
            HStack {
                stack
                    #if os(iOS)
                        .layoutPriority(1)
                    #endif
                Spacer()
                EntityTypeCapsule(id: id)
            }
        case .expandable:
            stack.onTapGesture {
                expand.toggle()
            }
        case .fixed:
            stack
        }
    }

    private var stack: some View {
        VStack(alignment: .leading, spacing: .small) {
            HStack(spacing: .small) {
                Image(systemName: image)
                Text(title.firstUppercased)
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
