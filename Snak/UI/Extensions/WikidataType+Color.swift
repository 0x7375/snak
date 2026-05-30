import SwiftUI

extension WikidataType {
    var displayColor: Color {
        switch self {
        case .item: .strongGreen
        case .property: .strongOrange
        }
    }
}
