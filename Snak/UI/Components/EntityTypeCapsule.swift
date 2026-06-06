import SwiftUI

extension WikidataType {
    var idPrefix: String {
        self == .item ? "Q" : "P"
    }
}

struct EntityTypeCapsule: View {
    let id: String
    let type: WikidataType
    let short: Bool

    init(_ id: String) {
        self.id = id
        self.type = WikidataType(id)
        #if os(watchOS)
            self.short = true
        #else
            self.short = false
        #endif
    }

    init(_ type: WikidataType) {
        self.id = type.idPrefix
        self.type = type
        self.short = true
    }

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
            .fontDesign(.monospaced)
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, .small)
            .padding(.vertical, .extraSmall)
            .background(color.opacity(0.15), in: Capsule())

        if !short {
            // show at least ~4 chars of the capsule
            text
                .frame(
                    minWidth: UIFont.preferredFont(forTextStyle: .caption1).pointSize * 5,
                    alignment: .trailing)
        } else {
            text
        }
    }
}
