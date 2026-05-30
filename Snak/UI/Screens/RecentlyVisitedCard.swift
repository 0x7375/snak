import SwiftUI

struct RecentlyVisitedCard: View {
    var item: Entity.Context

    var body: some View {
        NavigationLink(value: item) {
            VStack(alignment: .leading, spacing: .small) {
                HStack(alignment: .top) {
                    Text(item.label ?? item.id)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    EntityTypeCapsule(id: item.id, short: true)
                }

                Text(item.description ?? "Aucune description")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .padding(.medium)
            .frame(width: 160, height: 110, alignment: .topLeading)
            .background(
                Color.secondary.opacity(0.15),
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .buttonStyle(.plain)
    }
}
