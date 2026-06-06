import MapKit
import SwiftUI

extension Entity.Statement {
    func matches(_ query: String) -> Bool {
        let fields = [property.label, property.id, value.displayString, value.id]
        return fields.contains { $0?.localizedCaseInsensitiveContains(query) == true }
    }
}

struct DetailView: View {
    @Environment(\.openURL) private var openURL

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
        .navigationTitle(fallbackLabel?.smartCase ?? String(localized: "Details"))
        .task {
            guard entity == nil else { return }
            isLoading = true
            entity = try? await fetchEntity(
                entityID: initialData.id, type: WikidataType(initialData.id))
            isLoading = false
        }
        #if !os(watchOS)
            .searchable(text: $searchText, prompt: "Filter statements...")
        #endif
    }

    @ViewBuilder private func statementRow(_ stmt: Entity.Statement) -> some View {
        let safeLabel = stmt.property.label ?? stmt.property.id
        let route = stmt.value.route(propertyID: stmt.property.id)

        let style: DetailRow.Style = {
            switch route {
            case .entity(let id, _): return .entity(id: id)
            case .map: return .fixed
            case .link, .external: return .link
            case .image(_, let thumb, _): return .thumbnail(url: thumb)
            case nil: return .expandable
            }
        }()

        let row = DetailRow(
            title: safeLabel,
            value: stmt.value.displayString,
            image: stmt.value.systemImage,
            style: style
        )

        Group {
            if let route = stmt.value.route(propertyID: stmt.property.id) {
                switch route {
                case .entity(let id, let label):
                    NavigationLink(value: Entity.Context(id: id, label: label, description: nil)) {
                        row
                    }
                case .map(let lat, let lon, let p):
                    NavigationLink(
                        value: MapDestination(
                            title: fallbackLabel ?? initialData.id, latitude: lat, longitude: lon,
                            precision: p)
                    ) { row }
                case .link(let url):
                    Link(destination: url) {
                        row
                    }
                    .foregroundStyle(.primary)
                case .image(let file, _, let full):
                    NavigationLink(
                        value: ImageDestination(filename: file, url: full)
                    ) {
                        row
                    }
                case .external(let propID, let extID):
                    Button {
                        Task { await openExternal(propertyID: propID, externalID: extID) }
                    } label: {
                        row
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                row
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

    private func openExternal(propertyID: String, externalID: String) async {
        if let formatter = await fetchFormatterURL(propertyID: propertyID) {
            let urlString = formatter.replacingOccurrences(of: "$1", with: externalID)
            if let url = URL(string: urlString) {
                openURL(url)
                return
            }
        }

        if let fallback = URL(string: "https://www.wikidata.org/wiki/Property:\(propertyID)") {
            openURL(fallback)
        }
    }
}

struct DetailRow: View {
    enum Style {
        case expandable
        case fixed
        case entity(id: String)
        case thumbnail(url: URL)
        case link
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
                    #if !os(watchOS)
                        .layoutPriority(1)
                    #endif
                Spacer()
                EntityTypeCapsule(id: id)
            }
        case .expandable:
            stack.onTapGesture {
                expand.toggle()
            }
        case .thumbnail(let url):
            HStack {
                stack
                Spacer()
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle().fill(.quaternary)
                    }
                }
                .frame(width: .imageSize, height: .imageSize)
                .clipShape(RoundedRectangle(cornerRadius: .small))
            }
        case .link:
            HStack {
                stack
                Spacer()
                Image(systemName: "arrow.up.forward.square")
                    .foregroundStyle(.tertiary)
            }
        case .fixed:
            stack
        }
    }

    private var stack: some View {
        VStack(alignment: .leading, spacing: .small) {
            HStack(spacing: .small) {
                Image(systemName: image)
                Text(title.smartCase)
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            Text(value)
                .lineLimit(expand ? nil : 2)
        }
        #if !os(watchOS)
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
