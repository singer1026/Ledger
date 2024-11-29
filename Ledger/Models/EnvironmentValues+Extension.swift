import SwiftUI

private struct RefreshTriggerKey: EnvironmentKey {
    static let defaultValue: RefreshTrigger? = nil
}

extension EnvironmentValues {
    var refreshTrigger: RefreshTrigger? {
        get { self[RefreshTriggerKey.self] }
        set { self[RefreshTriggerKey.self] = newValue }
    }
} 