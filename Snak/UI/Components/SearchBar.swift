import SwiftUI

struct SearchBar: View {
    @Binding var query: String
    let prompt: String
    var submitted: Bool = false
    var insideToolbar: Bool = false
    var onSubmit: (() -> Void)?
    var onClear: (() -> Void)?

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
                                .padding(.trailing, insideToolbar ? .large : 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
        }
        .listRowBackground(Color.clear)
    }
}
