import SwiftUI

struct LoadingView: View {
    var text: String = String(localized: "This might take a few seconds...")

    @State private var showMessage = false

    var body: some View {
        VStack(spacing: .medium) {
            ProgressView()
                .padding(.top)

            if showMessage {
                Text(text)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .listRowBackground(Color.clear)
        .task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                showMessage = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
