import SwiftUI

extension EnvironmentValues {
    private struct NavigationKey: EnvironmentKey {
        static let defaultValue: (Entity.Context) -> Void = { _ in }
    }
    
    var navigate: (Entity.Context) -> Void {
        get { self[NavigationKey.self] }
        set { self[NavigationKey.self] = newValue }
    }
}
