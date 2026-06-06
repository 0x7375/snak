import Foundation

extension CGFloat {
    #if os(watchOS)
        static let extraSmall: CGFloat = 2
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16

        static let imageSize: CGFloat = 40
    #else
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32

        static let imageSize: CGFloat = 75
    #endif
}
