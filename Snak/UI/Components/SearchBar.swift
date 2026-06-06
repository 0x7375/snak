import SwiftUI

struct SearchBar: View {
    enum Style {
        case filter
        case search(Binding<WikidataType>)
    }

    @Binding var query: String
    let prompt: String
    let style: Style

    var submitted: Bool = false
    var onSubmit: (() -> Void)?
    var onClear: (() -> Void)?

    // workaround padding being stripped inside toolbar
    private var trailingPadding: CGFloat {
        if case .filter = style { return .large }
        return 0
    }

    var body: some View {
        HStack(spacing: .medium) {
            TextField(prompt, text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .onSubmit { onSubmit?() }
                .overlay(alignment: .trailing) {
                    if !query.isEmpty || submitted {
                        Button {
                            query = ""
                            onClear?()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.body)
                                .padding(.trailing, trailingPadding)
                        }
                        .buttonStyle(.plain)
                    } else if case .search(let mode) = style {
                        Button {
                            mode.wrappedValue =
                                mode.wrappedValue == .item ? .property : .item
                        } label: {
                            EntityTypeCapsule(mode.wrappedValue)
                        }
                        .buttonStyle(.plain)
                    }
                }
        }
        .listRowBackground(Color.clear)
    }
}
