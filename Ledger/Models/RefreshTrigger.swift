import SwiftUI

class RefreshTrigger: ObservableObject {
    @Published var shouldRefresh = false
    
    func refresh() {
        shouldRefresh.toggle()
    }
} 