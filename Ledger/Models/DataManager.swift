import Foundation
import CoreData

class DataManager {
    static let shared = DataManager()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "LedgerModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data加载失败: \(error.localizedDescription)")
            }
        }
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("保存失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 分类管理
    func createDefaultCategories() {
        let context = container.viewContext
        let categories = ["餐饮", "交通", "购物", "娱乐", "居家"]
        let icons = ["fork.knife", "car", "cart", "gamecontroller", "house"]
        
        for (index, name) in categories.enumerated() {
            let category = Category(context: context)
            category.id = UUID()
            category.name = name
            category.icon = icons[index]
            category.sortOrder = Int16(index)
        }
        
        save()
    }
    
    func addCategory(name: String, icon: String) {
        let context = container.viewContext
        let maxSortOrder = fetchCategories().map { $0.sortOrder }.max() ?? -1
        
        let category = Category(context: context)
        category.id = UUID()
        category.name = name
        category.icon = icon
        category.sortOrder = maxSortOrder + 1
        save()
    }
    
    func updateCategoryOrder(categories: [Category]) {
        let context = container.viewContext
        for (index, category) in categories.enumerated() {
            category.sortOrder = Int16(index)
        }
        save()
    }
    
    // MARK: - 交易记录管理
    func addTransaction(amount: Double, category: Category, note: String, date: Date) {
        let context = container.viewContext
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.amount = amount
        transaction.category = category
        transaction.note = note
        transaction.date = date
        save()
    }
    
    // MARK: - 数据查询
    func fetchCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)]
        do {
            return try container.viewContext.fetch(request)
        } catch {
            return []
        }
    }
    
    func fetchTransactions() -> [Transaction] {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        do {
            return try container.viewContext.fetch(request)
        } catch {
            return []
        }
    }
    
    // MARK: - 数据备份和恢复
    func backupData() -> URL? {
        guard let sourceURL = container.persistentStoreDescriptions.first?.url else { return nil }
        let fileManager = FileManager.default
        let backupURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LedgerBackup.sqlite")
        
        do {
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.copyItem(at: sourceURL, to: backupURL)
            return backupURL
        } catch {
            print("备份失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    func restoreData(from backupURL: URL) -> Bool {
        guard let targetURL = container.persistentStoreDescriptions.first?.url else { return false }
        let fileManager = FileManager.default
        
        do {
            if fileManager.fileExists(atPath: targetURL.path) {
                try fileManager.removeItem(at: targetURL)
            }
            try fileManager.copyItem(at: backupURL, to: targetURL)
            return true
        } catch {
            print("恢复失败: \(error.localizedDescription)")
            return false
        }
    }
} 