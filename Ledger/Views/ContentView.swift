import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TransactionListView()
                .tabItem {
                    Label("账单", systemImage: "list.bullet")
                }
                .tag(0)
            
            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.pie")
                }
                .tag(1)
            
            CategoryManageView()
                .tabItem {
                    Label("分类", systemImage: "folder")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(colorScheme == .dark ? .white : .blue)
    }
}

#Preview {
    ContentView()
} 