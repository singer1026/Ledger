import SwiftUI
import Charts

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction>
    
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedChartType: ChartType = .pie
    @State private var selectedCategory: String?
    @State private var categoryColors: [String: Color] = [:]
    
    private let colors: [Color] = [.blue, .green, .orange, .red, .purple, .pink]
    
    enum TimeRange: String, CaseIterable {
        case week = "本周"
        case month = "本月"
        case year = "今年"
    }
    
    enum ChartType: String, CaseIterable {
        case pie = "饼图"
        case bar = "柱状图"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("时间范围", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Picker("图表类型", selection: $selectedChartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if selectedChartType == .pie {
                    PieChartView(
                        data: getCategoryData(),
                        selectedCategory: $selectedCategory
                    )
                    .animation(.easeInOut, value: selectedTimeRange)
                } else {
                    BarChartView(
                        data: getCategoryData(),
                        selectedCategory: $selectedCategory
                    )
                    .animation(.easeInOut, value: selectedTimeRange)
                }
                
                List {
                    ForEach(getCategoryData(), id: \.category) { item in
                        CategoryStatRow(
                            item: item,
                            isSelected: selectedCategory == item.category,
                            onTap: {
                                withAnimation {
                                    if selectedCategory == item.category {
                                        selectedCategory = nil
                                    } else {
                                        selectedCategory = item.category
                                    }
                                }
                            }
                        )
                    }
                }
            }
            .navigationTitle("统计")
            .onAppear {
                initializeCategoryColors()
            }
        }
    }
    
    private func initializeCategoryColors() {
        let allCategories = Set(transactions.compactMap { $0.category?.name })
        for (index, category) in allCategories.enumerated() {
            if categoryColors[category] == nil {
                categoryColors[category] = colors[index % colors.count]
            }
        }
    }
    
    private func getCategoryData() -> [ChartData] {
        let filteredTransactions = transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return isDateInRange(date)
        }
        
        var categoryAmounts: [String: Double] = [:]
        for transaction in filteredTransactions {
            let categoryName = transaction.category?.name ?? "未分类"
            categoryAmounts[categoryName, default: 0] += abs(transaction.amount)
        }
        
        return categoryAmounts.map { item in
            ChartData(
                category: item.key,
                amount: item.value,
                color: categoryColors[item.key] ?? colors[categoryColors.count % colors.count]
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    private func isDateInRange(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .week:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return false }
            return date >= weekStart
        case .month:
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return false }
            return date >= monthStart
        case .year:
            guard let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now)) else { return false }
            return date >= yearStart
        }
    }
}

struct CategoryStatRow: View {
    let item: ChartData
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(item.color)
                .frame(width: 10, height: 10)
            Text(item.category)
            Spacer()
            Text(String(format: "¥%.2f", item.amount))
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .opacity(isSelected || !isSelected ? 1 : 0.5)
    }
}

struct ChartData: Equatable {
    let category: String
    let amount: Double
    let color: Color
    
    static func == (lhs: ChartData, rhs: ChartData) -> Bool {
        lhs.category == rhs.category &&
        lhs.amount == rhs.amount
        // 注意：我们不比较color，因为SwiftUI的Color不遵循Equatable
    }
}

struct PieChartView: View {
    let data: [ChartData]
    @Binding var selectedCategory: String?
    
    var body: some View {
        Chart {
            ForEach(data, id: \.category) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .foregroundStyle(item.color.opacity(getOpacity(for: item.category)))
            }
        }
        .frame(height: 300)
        .padding()
        .animation(.easeInOut, value: selectedCategory)
    }
    
    private func getOpacity(for category: String) -> Double {
        if selectedCategory == nil || selectedCategory == category {
            return 1.0
        }
        return 0.3
    }
}

struct BarChartView: View {
    let data: [ChartData]
    @Binding var selectedCategory: String?
    @State private var showBars = false
    
    private let barWidth: CGFloat = 60
    private let barSpacing: CGFloat = 20
    
    private var chartWidth: CGFloat {
        CGFloat(data.count) * (barWidth + barSpacing)
    }
    
    private var maxAmount: Double {
        data.map { $0.amount }.max() ?? 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    chartContent
                        .frame(width: max(chartWidth, geometry.size.width))
                }
                .onChange(of: selectedCategory) { _, newValue in
                    if let category = newValue,
                       let index = data.firstIndex(where: { $0.category == category }) {
                        let screenWidth = geometry.size.width
                        let itemWidth = barWidth + barSpacing
                        let offset = CGFloat(index) * itemWidth
                        let centerOffset = (screenWidth - itemWidth) / 2
                        let scrollOffset = max(0, offset - centerOffset)
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if let scrollView = proxy.scrollView {
                                scrollView.setContentOffset(CGPoint(x: scrollOffset, y: 0), animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var chartContent: some View {
        Chart {
            ForEach(data, id: \.category) { item in
                BarMark(
                    x: .value("Category", item.category),
                    y: .value("Amount", showBars ? item.amount : 0)
                )
                .foregroundStyle(item.color.opacity(getOpacity(for: item.category)))
            }
        }
        .chartXAxis {
            categoryAxis
        }
        .chartYAxis {
            amountAxis
        }
        .chartYScale(domain: 0...maxAmount * 1.1)
        .padding(.horizontal)
        .animation(.easeInOut, value: selectedCategory)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                showBars = true
            }
        }
        .onChange(of: data) { oldValue, newValue in
            handleDataChange(oldValue: oldValue, newValue: newValue)
        }
    }
    
    private var categoryAxis: some AxisContent {
        AxisMarks(preset: .aligned) { value in
            if let category = value.as(String.self) {
                AxisValueLabel {
                    Text(category)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
    }
    
    private var amountAxis: some AxisContent {
        AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
            if let amount = value.as(Double.self) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    Text("¥\(formatAmount(amount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func handleDataChange(oldValue: [ChartData], newValue: [ChartData]) {
        let oldCategories = Set(oldValue.map { $0.category })
        let newCategories = Set(newValue.map { $0.category })
        if oldCategories != newCategories {
            showBars = false
            withAnimation(.easeInOut(duration: 0.8)) {
                showBars = true
            }
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 10000 {
            return String(format: "%.1f万", amount / 10000)
        } else {
            return String(format: "%.0f", amount)
        }
    }
    
    private func getOpacity(for category: String) -> Double {
        if selectedCategory == nil || selectedCategory == category {
            return 1.0
        }
        return 0.3
    }
}

extension ScrollViewProxy {
    var scrollView: UIScrollView? {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let scrollView = child.value as? UIScrollView {
                return scrollView
            }
        }
        return nil
    }
}

#Preview {
    StatisticsView()
} 