import Foundation

extension CGFloat {
    #if os(watchOS)
        static let extraSmall: CGFloat = 3
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
        static let extraLarge: CGFloat = 20

        static let thumbnailSize: CGFloat = 40
        static let imageSize: CGFloat = 400
    #else
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32

        static let thumbnailSize: CGFloat = 75
        static let imageSize: CGFloat = 1000
    #endif
}
