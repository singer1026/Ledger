import SwiftUI

struct TransactionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.refreshTrigger) private var refreshTrigger
    
    let transaction: Transaction
    @State private var showingDeleteAlert = false
    @State private var isEditing = false
    
    // 编辑状态的临时数据
    @State private var editedAmount: String = ""
    @State private var editedNote: String = ""
    @State private var editedDate: Date = Date()
    @State private var editedCategory: Category?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("金额")) {
                    if isEditing {
                        TextField("输入金额", text: $editedAmount)
                            .keyboardType(.decimalPad)
                    } else {
                        HStack {
                            Text(String(format: "¥%.2f", transaction.amount))
                                .font(.title2)
                                .foregroundColor(transaction.amount < 0 ? .red : .green)
                        }
                    }
                }
                
                Section(header: Text("分类")) {
                    if isEditing {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(categories, id: \.id) { category in
                                    CategoryButton(
                                        icon: category.icon ?? "questionmark.circle",
                                        name: category.name ?? "",
                                        isSelected: category == editedCategory
                                    ) {
                                        editedCategory = category
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 80)
                    } else {
                        HStack {
                            Image(systemName: transaction.category?.icon ?? "questionmark.circle")
                                .foregroundColor(.accentColor)
                            Text(transaction.category?.name ?? "未分类")
                        }
                    }
                }
                
                Section(header: Text("备注")) {
                    if isEditing {
                        TextField("添加备注", text: $editedNote)
                    } else if let note = transaction.note, !note.isEmpty {
                        Text(note)
                    }
                }
                
                Section(header: Text("时间")) {
                    if isEditing {
                        DatePicker("选择时间", selection: $editedDate, displayedComponents: [.date, .hourAndMinute])
                    } else if let date = transaction.date {
                        Text(formatDate(date))
                    }
                }
                
                if !isEditing {
                    Section {
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            HStack {
                                Spacer()
                                Text("删除记录")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("交易详情")
            .navigationBarItems(
                leading: Button(isEditing ? "取消" : "编辑") {
                    if isEditing {
                        resetEditingData()
                    }
                    isEditing.toggle()
                },
                trailing: Group {
                    if isEditing {
                        Button("保存") {
                            saveChanges()
                        }
                        .disabled(!isValidInput())
                    } else {
                        Button("完成") {
                            dismiss()
                        }
                    }
                }
            )
            .dismissKeyboardOnTap()
            .onAppear {
                resetEditingData()
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deleteTransaction()
                }
            } message: {
                Text("确定要删除这条交易记录吗？此操作不可撤销。")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
    
    private func deleteTransaction() {
        viewContext.delete(transaction)
        do {
            try viewContext.save()
            refreshTrigger?.refresh()
            dismiss()
        } catch {
            print("删除失败: \(error.localizedDescription)")
        }
    }
    
    private func resetEditingData() {
        editedAmount = String(format: "%.2f", abs(transaction.amount))
        editedNote = transaction.note ?? ""
        editedDate = transaction.date ?? Date()
        editedCategory = transaction.category
    }
    
    private func isValidInput() -> Bool {
        guard let _ = Double(editedAmount), editedCategory != nil else {
            return false
        }
        return true
    }
    
    private func saveChanges() {
        guard let amountDouble = Double(editedAmount) else { return }
        
        transaction.amount = amountDouble
        transaction.category = editedCategory
        transaction.note = editedNote
        transaction.date = editedDate
        
        do {
            try viewContext.save()
            refreshTrigger?.refresh()
            isEditing = false
        } catch {
            print("保存失败: \(error.localizedDescription)")
        }
    }
}

struct CategoryButton: View {
    let icon: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
            
            Text(name)
                .font(.caption)
        }
        .onTapGesture(perform: action)
    }
}

#Preview {
    let context = DataManager.shared.container.viewContext
    let transaction = Transaction(context: context)
    transaction.amount = -100
    transaction.date = Date()
    transaction.note = "测试交易"
    
    let category = Category(context: context)
    category.name = "餐饮"
    category.icon = "fork.knife"
    transaction.category = category
    
    return TransactionDetailView(transaction: transaction)
} 