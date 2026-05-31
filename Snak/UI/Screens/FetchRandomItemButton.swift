import SwiftUI

struct FetchRandomItemButton: View {
    @Environment(\.navigate) var navigate

    @State private var failed = false
    @State private var isFetching = false

    var body: some View {
        Button {
            Task {
                guard !isFetching else { return }

                isFetching = true
                defer { isFetching = false }

                if let id = try? await fetchRandomItems().first {
                    navigate(id)
                } else {
                    failed = true
                }
            }
        } label: {
            if isFetching {
                LoadingView()
            } else if failed {
                Label("Retry", systemImage: "arrow.counterclockwise")
            } else {
                VStack(spacing: .small) {
                    Image(systemName: "dice.fill")
                        .font(.title)
                    Text("Random entity")
                        .fontWeight(.semibold)
                }
            }
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.top, .extraLarge)
        .buttonStyle(.plain)
    }
}
