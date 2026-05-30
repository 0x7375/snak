import SwiftUI

#if DEBUG
    extension NavigationPath {
        private static let devURL = URL.documentsDirectory
            .appendingPathComponent("navpath_dev.json")

        func save() {
            guard let representation = codable,
                let data = try? JSONEncoder().encode(representation)
            else { return }
            try? data.write(to: NavigationPath.devURL)
        }

        static func restore() -> NavigationPath {
            guard let data = try? Data(contentsOf: devURL),
                let coded = try? JSONDecoder().decode(CodableRepresentation.self, from: data)
            else {
                return NavigationPath()
            }
            return NavigationPath(coded)
        }
    }
#endif
