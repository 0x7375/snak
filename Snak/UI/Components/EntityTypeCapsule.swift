import SwiftUI

struct EntityTypeCapsule: View {
    let id: String
    #if os(watchOS)
        var short: Bool = true
    #else
        var short: Bool = false
    #endif
    var type: WikidataType { WikidataType(id) }

    private var displayText: String {
        if short {
            String(id.prefix(1))
        } else {
            id
        }
    }

    var body: some View {
        let color = type.displayColor
        let text = Text(displayText)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, .small)
            .padding(.vertical, .extraSmall)
            .background(color.opacity(0.15), in: Capsule())

        if !short {
            // show at least ~4 chars of the capsule
            text
                .frame(
                    minWidth: UIFont.preferredFont(forTextStyle: .caption1).pointSize * 5)
        } else {
            text
        }
    }
}
