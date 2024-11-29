//
//  LedgerApp.swift
//  Ledger
//
//  Created by Rick on 2024/11/29.
//

import SwiftUI

@main
struct LedgerApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    let persistenceController = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onAppear {
                    if persistenceController.fetchCategories().isEmpty {
                        persistenceController.createDefaultCategories()
                    }
                }
        }
    }
}
