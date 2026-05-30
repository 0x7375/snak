import SwiftUI

struct SearchResultRow: View {
    let result: Entity.Context

    var body: some View {
        NavigationLink(value: result) {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text(result.label ?? result.id)
                        .font(.headline)
                        .lineLimit(1)

                    if let desc = result.description {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                #if os(iOS)
                    .layoutPriority(1)
                #endif

                Spacer()

                EntityTypeCapsule(id: result.id)
            }
        }
        .buttonStyle(.plain)
    }
}
