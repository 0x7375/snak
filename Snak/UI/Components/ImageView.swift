import SwiftUI

#if !os(watchOS)
    import Zoomable
#endif

struct ImageDestination: Hashable, Codable {
    let filename: String
    let url: URL
}

struct ImageView: View {
    let dest: ImageDestination

    var body: some View {
        AsyncImage(url: dest.url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
                    #if !os(watchOS)
                        .zoomable()
                    #endif
            } else {
                LoadingView()
            }
        }
        .navigationTitle(dest.filename)
        .navigationBarTitleDisplayMode(.inline)
    }
}
