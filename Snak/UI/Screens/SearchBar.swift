import SwiftUI

struct SearchBar: View {
    @Binding var query: String
    var onSubmit: () -> Void
    var onClear: () -> Void
    var resultsShown: Bool

    var body: some View {
        HStack(spacing: .medium) {
            TextField("Rechercher...", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .onSubmit { onSubmit() }
                .overlay(alignment: .trailing) {
                    if !query.isEmpty || resultsShown {
                        Button {
                            query = ""
                            onClear()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.body)
                        }
                        .buttonStyle(.plain)
                    }
                }
        }
        .listRowBackground(Color.clear)
    }
}
