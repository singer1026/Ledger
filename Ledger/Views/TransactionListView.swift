import SwiftUI

struct TransactionListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var refreshTrigger = RefreshTrigger()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction>
    
    @State private var showingAddSheet = false
    @State private var selectedTransaction: Transaction?
    @State private var showingFilterSheet = false
    @State private var selectedCategory: Category?
    @State private var dateRange: DateRange = .all
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showingDeleteAlert = false
    @State private var transactionToDelete: Transaction?
    
    enum DateRange: String, CaseIterable {
        case all = "全部"
        case today = "今天"
        case week = "本周"
        case month = "本月"
        case custom = "自定义"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterPreviewBarView
                transactionListView
            }
            .navigationTitle("账单")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFilterSheet = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasActiveFilters ? .accentColor : .primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTransactionView()
                    .environment(\.refreshTrigger, refreshTrigger)
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailView(transaction: transaction)
                    .environment(\.refreshTrigger, refreshTrigger)
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(
                    selectedCategory: $selectedCategory,
                    dateRange: $dateRange,
                    startDate: $startDate,
                    endDate: $endDate
                )
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {
                    transactionToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let transaction = transactionToDelete {
                        deleteTransaction(transaction)
                        transactionToDelete = nil
                    }
                }
            } message: {
                Text("确定要删除这条交易记录吗？此操作不可撤销。")
            }
        }
    }
    
    private var filterPreviewBarView: some View {
        Group {
            if selectedCategory != nil || dateRange != .all {
                FilterPreviewBar(
                    category: selectedCategory,
                    dateRange: dateRange,
                    onClearCategory: { selectedCategory = nil },
                    onClearDateRange: { dateRange = .all }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var transactionListView: some View {
        List {
            ForEach(groupTransactionsByDate(), id: \.0) { date, transactions in
                Section(header: Text(formatDate(date))) {
                    ForEach(transactions, id: \.id) { transaction in
                        transactionRowView(for: transaction)
                    }
                }
            }
        }
        .animation(.default, value: filteredTransactions)
    }
    
    private func transactionRowView(for transaction: Transaction) -> some View {
        TransactionRow(transaction: transaction)
            .contextMenu {
                Button(role: .destructive) {
                    transactionToDelete = transaction
                    showingDeleteAlert = true
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    transactionToDelete = transaction
                    showingDeleteAlert = true
                } label: {
                    Label("删除", systemImage: "trash")
                }
                .tint(.red)
                
                Button {
                    selectedTransaction = transaction
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
                .tint(.blue)
            }
            .onTapGesture {
                selectedTransaction = transaction
            }
    }
    
    var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            let matchesCategory = selectedCategory == nil || transaction.category == selectedCategory
            let matchesDate = isDateInRange(transaction.date ?? Date())
            return matchesCategory && matchesDate
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedCategory != nil || dateRange != .all
    }
    
    private func groupTransactionsByDate() -> [(Date, [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date ?? Date())
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    private func deleteTransaction(_ transaction: Transaction) {
        withAnimation {
            viewContext.delete(transaction)
            do {
                try viewContext.save()
                refreshTrigger.refresh()
            } catch {
                print("删除失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func isDateInRange(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        switch dateRange {
        case .all:
            return true
        case .today:
            return calendar.isDateInToday(date)
        case .week:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else { return false }
            return startOfDay >= weekStart
        case .month:
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return false }
            return startOfDay >= monthStart
        case .custom:
            let startOfStartDate = calendar.startOfDay(for: startDate)
            let endOfEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
            return startOfDay >= startOfStartDate && startOfDay <= endOfEndDate
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.category?.icon ?? "questionmark.circle")
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(transaction.category?.name ?? "未分类")
                    .font(.headline)
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(String(format: "¥%.2f", transaction.amount))
                .font(.headline)
                .foregroundColor(transaction.amount < 0 ? .red : .green)
        }
        .padding(.vertical, 8)
    }
}

struct FilterPreviewBar: View {
    let category: Category?
    let dateRange: TransactionListView.DateRange
    let onClearCategory: () -> Void
    let onClearDateRange: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let category = category {
                    FilterTag(
                        icon: category.icon ?? "tag",
                        text: category.name ?? "",
                        onClear: onClearCategory
                    )
                }
                
                if dateRange != .all {
                    FilterTag(
                        icon: "calendar",
                        text: dateRange.rawValue,
                        onClear: onClearDateRange
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct FilterTag: View {
    let icon: String
    let text: String
    let onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var selectedCategory: Category?
    @Binding var dateRange: TransactionListView.DateRange
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("分类")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            FilterCategoryButton(
                                icon: "tag",
                                name: "全部",
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(categories, id: \.id) { category in
                                FilterCategoryButton(
                                    icon: category.icon ?? "questionmark.circle",
                                    name: category.name ?? "",
                                    isSelected: category == selectedCategory
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 80)
                }
                
                Section(header: Text("时间")) {
                    Picker("时间范围", selection: $dateRange) {
                        ForEach(TransactionListView.DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    
                    if dateRange == .custom {
                        DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                        DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("筛选")
            .navigationBarItems(
                leading: Button("重置") {
                    selectedCategory = nil
                    dateRange = .all
                },
                trailing: Button("完成") {
                    dismiss()
                }
            )
        }
    }
}

struct FilterCategoryButton: View {
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
    TransactionListView()
} 
