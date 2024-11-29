import SwiftUI

struct AddTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.refreshTrigger) private var refreshTrigger
    
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var date = Date()
    @State private var selectedCategory: Category?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("金额")) {
                    TextField("输入金额", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("分类")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(categories, id: \.id) { category in
                                AddCategoryButton(
                                    category: category,
                                    isSelected: selectedCategory?.id == category.id
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 80)
                }
                
                Section(header: Text("备注")) {
                    TextField("添加备注", text: $note)
                }
                
                Section(header: Text("日期")) {
                    DatePicker("选择日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("新增记录")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    saveTransaction()
                }
                .disabled(amount.isEmpty || selectedCategory == nil)
            )
            .dismissKeyboardOnTap()
        }
    }
    
    private func saveTransaction() {
        guard let amountDouble = Double(amount),
              let category = selectedCategory else { return }
        
        DataManager.shared.addTransaction(
            amount: amountDouble,
            category: category,
            note: note,
            date: date
        )
        
        refreshTrigger?.refresh()
        dismiss()
    }
}

struct AddCategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: category.icon ?? "questionmark.circle")
                .font(.system(size: 24))
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
            
            Text(category.name ?? "")
                .font(.caption)
        }
        .onTapGesture(perform: action)
    }
}

#Preview {
    AddTransactionView()
} 