import SwiftUI

struct CategoryManageView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    @State private var showingAddSheet = false
    @State private var selectedCategory: Category?
    @State private var editMode: EditMode = .inactive
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: Category?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories, id: \.id) { category in
                    CategoryRow(category: category)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if editMode == .inactive {
                                selectedCategory = category
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if editMode == .inactive {
                                Button(role: .destructive) {
                                    categoryToDelete = category
                                    showingDeleteAlert = true
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                }
                .onMove { source, destination in
                    var updatedCategories = Array(categories)
                    updatedCategories.move(fromOffsets: source, toOffset: destination)
                    DataManager.shared.updateCategoryOrder(categories: updatedCategories)
                }
            }
            .navigationTitle("分类管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingAddSheet) {
                AddCategoryView()
            }
            .sheet(item: $selectedCategory) { category in
                EditCategoryView(category: category)
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {
                    categoryToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let category = categoryToDelete {
                        deleteCategory(category)
                        categoryToDelete = nil
                    }
                }
            } message: {
                if let category = categoryToDelete {
                    Text("确定要删除分类\(category.name ?? "")吗？此操作不可撤销。")
                } else {
                    Text("确定要删除选中的分类吗？此操作不可撤销。")
                }
            }
        }
    }
    
    private func deleteCategory(_ category: Category) {
        withAnimation {
            viewContext.delete(category)
            do {
                try viewContext.save()
            } catch {
                print("删除分类失败: \(error.localizedDescription)")
            }
        }
    }
}

// 添加安全数组访问扩展
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct CategoryRow: View {
    let category: Category
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        HStack {
            Image(systemName: category.icon ?? "questionmark.circle")
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            Text(category.name ?? "")
                .font(.headline)
            
            Spacer()
            
            if editMode?.wrappedValue == .active {
//                Image(systemName: "line.3.horizontal")
//                    .foregroundColor(.gray)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct AddCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "tag"
    
    static let icons = [
        "tag", "cart", "car", "house", "fork.knife", "gamecontroller",
        "gift", "heart", "book", "cross.case", "airplane", "bus",
        "tram", "train.side.front.car", "bicycle", "figure.walk",
        "bag", "creditcard", "banknote", "phone", "laptopcomputer", "display",
        "tv", "headphones", "camera", "paintbrush", "hammer", "wrench",
        "leaf", "pawprint", "film", "theatermasks", "sportscourt",
        "figure.basketball", "soccerball", "figure.tennis"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("分类名称", text: $name)
                }
                
                Section(header: Text("图标")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 20) {
                        ForEach(AddCategoryView.icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 24))
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color.accentColor : Color.clear)
                                .foregroundColor(selectedIcon == icon ? .white : .primary)
                                .clipShape(Circle())
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("新增分类")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    saveCategory()
                }
                .disabled(name.isEmpty)
            )
            .dismissKeyboardOnTap()
        }
    }
    
    private func saveCategory() {
        DataManager.shared.addCategory(name: name, icon: selectedIcon)
        dismiss()
    }
}

struct EditCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let category: Category
    @State private var name: String
    @State private var selectedIcon: String
    
    init(category: Category) {
        self.category = category
        _name = State(initialValue: category.name ?? "")
        _selectedIcon = State(initialValue: category.icon ?? "tag")
    }

    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("分类名称", text: $name)
                }
                
                Section(header: Text("图标")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 20) {
                        ForEach(AddCategoryView.icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 24))
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color.accentColor : Color.clear)
                                .foregroundColor(selectedIcon == icon ? .white : .primary)
                                .clipShape(Circle())
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("编辑分类")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    updateCategory()
                }
                .disabled(name.isEmpty)
            )
            .dismissKeyboardOnTap()
        }
    }
    
    private func updateCategory() {
        category.name = name
        category.icon = selectedIcon
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("更新分类失败: \(error.localizedDescription)")
        }
    }
}

#Preview {
    CategoryManageView()
} 
