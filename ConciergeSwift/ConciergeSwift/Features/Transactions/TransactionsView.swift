//
//  TransactionsView.swift
//  ConciergeSwift
//
//  Transactions analysis with date range selector
//  White background + Fixed dark gradient header card
//

import SwiftUI
import Charts

struct TransactionsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Date()
    @State private var showDatePicker: Bool = false
    
    private var dateLabel: String {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        
        if startDay == endDay {
            if calendar.isDateInToday(startDate) {
                return "Hoje"
            } else if calendar.isDateInYesterday(startDate) {
                return "Ontem"
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "pt_BR")
                formatter.dateFormat = "dd MMM"
                return formatter.string(from: startDate)
            }
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd MMM"
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // White background (like Home)
            Theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Fixed dark gradient header card with summary
                fixedHeader
                
                // Scrollable content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(Theme.gold)
                    Spacer()
                } else if viewModel.filteredTransactions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.surfaceHover)
                        Text("Nenhuma transação encontrada.")
                            .foregroundColor(Theme.textTertiary)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            if !viewModel.expenseCategorySums.isEmpty {
                                expensesChart
                            }
                            
                            timeline
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .onAppear {
            guard let uid = authService.currentUser?.id else { return }
            Task {
                await viewModel.loadTransactions(userId: uid)
                viewModel.filterByRange(start: startDate, end: endDate)
            }
        }
        .overlay {
            if showDatePicker {
                TransactionsFilterView(
                    isPresented: $showDatePicker,
                    startDate: $startDate,
                    endDate: $endDate,
                    onApply: applyFilter
                )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showDatePicker)
    }
    
    // MARK: - Fixed Header (Gradient Card + Summary Cards)
    private var fixedHeader: some View {
        VStack(spacing: 0) {
            // Title + Date Selector
            HStack {
                Text("Transações")
                    .font(.custom("Georgia", size: 28))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.4), radius: 8, x: 0, y: 0)
                
                Spacer()
                
                Button(action: { showDatePicker = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(dateLabel)
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(Theme.gold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            // Summary Cards (Income / Expense)
            summaryCards
                .padding(.bottom, 24)
        }
        .background(
            ZStack {
                Color(hex: "080B12")
                
                LinearGradient(
                    colors: [
                        Color(hex: "080B12"),
                        Color(hex: "121624"),
                        Color(hex: "1C2235")
                    ],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
                .blur(radius: 20)
                
                MinimalistPatternView()
                    .opacity(0.4)
            }
            .clipShape(RoundedCorner(radius: 40, corners: [.bottomLeft, .bottomRight]))
            .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 10)
            .ignoresSafeArea(edges: .top)
        )
    }
    
    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: 14) {
            // Income
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "1DD1A1").opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: "arrow.down.left")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "1DD1A1"))
                    }
                    Text("ENTRADAS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.45))
                }
                
                Text(viewModel.totalIncome.formattedCurrency)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.white.opacity(0.04))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            
            // Expense
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Theme.gold.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.gold)
                    }
                    Text("SAÍDAS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.45))
                }
                
                Text(viewModel.totalExpense.formattedCurrency)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.white.opacity(0.04))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
    }
    

    
    // MARK: - Sheet Preset Button
    private func sheetPresetButton(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(active ? .white : Theme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(active ? Theme.gold.opacity(0.3) : Color.white.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(active ? Theme.gold.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Preset Checks
    private var isTodayPreset: Bool {
        let cal = Calendar.current
        return cal.isDateInToday(startDate) && cal.isDateInToday(endDate)
    }
    
    private var isYesterdayPreset: Bool {
        let cal = Calendar.current
        return cal.isDateInYesterday(startDate) && cal.isDateInYesterday(endDate)
    }
    
    private var is7DaysPreset: Bool {
        let cal = Calendar.current
        let expected = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date()))!
        return cal.startOfDay(for: startDate) == expected && cal.isDateInToday(endDate)
    }
    
    private var is30DaysPreset: Bool {
        let cal = Calendar.current
        let expected = cal.date(byAdding: .day, value: -29, to: cal.startOfDay(for: Date()))!
        return cal.startOfDay(for: startDate) == expected && cal.isDateInToday(endDate)
    }
    
    private func applyFilter() {
        viewModel.filterByRange(start: startDate, end: endDate)
    }
    
    // MARK: - Timeline Statement
    private var timeline: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(viewModel.groupedTransactions, id: \.date) { group in
                VStack(alignment: .leading, spacing: 10) {
                    // Date Header
                    Text(group.date.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Theme.textTertiary)
                        .padding(.horizontal, 24)
                    
                    // Transactions List — Grayish cards
                    VStack(spacing: 6) {
                        ForEach(group.transactions) { transaction in
                            TransactionRowView(
                                transaction: transaction,
                                formattedAmount: transaction.amount.formattedCurrency
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Expenses Donut Chart
    private var expensesChart: some View {
        VStack(spacing: 16) {
            Text("Despesas por Categoria")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            
            Chart(viewModel.expenseCategorySums, id: \.category) { item in
                SectorMark(
                    angle: .value("Valor", item.amount),
                    innerRadius: .ratio(0.75),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(categoryColor(for: item.category))
            }
            .frame(height: 180)
            .padding(.horizontal, 40)
            
            // Native-looking Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                ForEach(viewModel.expenseCategorySums, id: \.category) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(categoryColor(for: item.category))
                            .frame(width: 8, height: 8)
                        
                        Text(item.category)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(item.amount.formattedCurrency)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // Premium Category Colors
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Alimentação": return Color(hex: "E8C382") // Vintage Gold
        case "Transporte": return Color(hex: "1DD1A1") // Teal
        case "Casa": return Color(hex: "8A2BE2") // Deep Purple
        case "Saúde": return Color(hex: "FF6B6B") // Soft Red
        case "Educação": return Color(hex: "48DBFB") // Cyan
        case "Lazer": return Color(hex: "FF9F43") // Orange
        default: return Theme.surfaceHover // Gray fallback
        }
    }
}

// MARK: - Transaction Row (Surface-toned Card)
struct TransactionRowView: View {
    let transaction: Transaction
    let formattedAmount: String
    
    var isIncome: Bool {
        transaction.type == .income
    }
    
    var categoryIcon: String {
        TransactionCategory(rawValue: transaction.category)?.icon ?? "ellipsis.circle"
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(isIncome ? Color(hex: "1DD1A1").opacity(0.1) : Theme.surfaceHover)
                    .frame(width: 44, height: 44)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 16))
                    .foregroundColor(isIncome ? Color(hex: "1DD1A1") : Theme.textSecondary)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.description)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                Text(transaction.category)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textTertiary)
            }
            
            Spacer()
            
            // Amount
            Text((isIncome ? "+ " : "- ") + formattedAmount)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isIncome ? Color(hex: "1DD1A1") : Theme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Chart Data Model
struct TransactionCategorySum: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}

// MARK: - ViewModel
@MainActor
class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var filteredTransactions: [Transaction] = []
    @Published var isLoading = false
    
    // Financial Summaries
    @Published var totalIncome: Double = 0
    @Published var totalExpense: Double = 0
    
    var balance: Double {
        totalIncome - totalExpense
    }
    
    // Grouped for Timeline
    @Published var groupedTransactions: [(date: String, transactions: [Transaction])] = []
    
    // Chart Data
    @Published var expenseCategorySums: [TransactionCategorySum] = []
    
    private let firestoreService = FirestoreService.shared
    
    // Formatting is handled by Double extension
    
    func loadTransactions(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        print("🔍 Fetching for userId: \(userId)")
        
        do {
            let allTransactions = try await firestoreService.fetchTransactions(userId: userId)
            print("✅ Fetched \(allTransactions.count) transactions")
            
            // Sort by newest first
            self.transactions = allTransactions.sorted { $0.createdAt > $1.createdAt }
            
            // Default: show today
            let today = Calendar.current.startOfDay(for: Date())
            filterByRange(start: today, end: Date())
            
        } catch {
            print("❌ Error loading transactions: \(error)")
        }
    }
    
    func filterByRange(start: Date, end: Date) {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: end) ?? end)
        
        filteredTransactions = transactions.filter {
            let txDate = $0.createdAt
            return txDate >= startDay && txDate < endDay
        }
        
        // Recalculate totals
        totalIncome = filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        totalExpense = filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        
        // Regroup
        groupTransactionsByDate()
        calculateExpenseCategorySums()
    }
    
    private func calculateExpenseCategorySums() {
        let expenses = filteredTransactions.filter { $0.type == .expense }
        var dict: [String: Double] = [:]
        
        for tx in expenses {
            dict[tx.category, default: 0] += tx.amount
        }
        
        // Sort descending by amount
        expenseCategorySums = dict.map { TransactionCategorySum(category: $0.key, amount: $0.value) }
                                  .sorted { $0.amount > $1.amount }
    }
    
    private func groupTransactionsByDate() {
        let calendar = Calendar.current
        var grouped: [Date: [Transaction]] = [:]
        
        for transaction in filteredTransactions {
            let date = calendar.startOfDay(for: transaction.createdAt)
            grouped[date, default: []].append(transaction)
        }
        
        let sortedDates = grouped.keys.sorted(by: >)
        
        var result: [(date: String, transactions: [Transaction])] = []
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pt_BR")
        dateFormatter.dateFormat = "dd 'de' MMM"
        
        for date in sortedDates {
            let label: String
            if calendar.isDateInToday(date) {
                label = "Hoje"
            } else if calendar.isDateInYesterday(date) {
                label = "Ontem"
            } else {
                label = dateFormatter.string(from: date).capitalized
            }
            result.append((date: label, transactions: grouped[date]!))
        }
        
        self.groupedTransactions = result
    }
}

// MARK: - Date Preset Button
struct DatePresetButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : Theme.gold)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Theme.gold.opacity(0.3) : Color.white.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Theme.gold.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Transactions Filter Modal
struct TransactionsFilterView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    var onApply: () -> Void
    
    // MARK: - Preset Checks
    private var isTodayPreset: Bool {
        let cal = Calendar.current
        return cal.isDateInToday(startDate) && cal.isDateInToday(endDate)
    }
    
    private var isYesterdayPreset: Bool {
        let cal = Calendar.current
        return cal.isDateInYesterday(startDate) && cal.isDateInYesterday(endDate)
    }
    
    private var is7DaysPreset: Bool {
        let cal = Calendar.current
        let expected = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date()))!
        return cal.startOfDay(for: startDate) == expected && cal.isDateInToday(endDate)
    }
    
    private var is30DaysPreset: Bool {
        let cal = Calendar.current
        let expected = cal.date(byAdding: .day, value: -29, to: cal.startOfDay(for: Date()))!
        return cal.startOfDay(for: startDate) == expected && cal.isDateInToday(endDate)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background
            Color.black.opacity(0.2)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.2)
                )
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPresented = false }
                }
            
            // Floating card
            VStack(spacing: 22) {
                // Header
                HStack {
                    Text("Período")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPresented = false } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                
                // Presets — 2x2 grid
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        sheetPresetButton("Ontem", active: isYesterdayPreset) {
                            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                            startDate = Calendar.current.startOfDay(for: yesterday)
                            endDate = yesterday
                            onApply()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPresented = false }
                        }
                        sheetPresetButton("Hoje", active: isTodayPreset) {
                            startDate = Calendar.current.startOfDay(for: Date())
                            endDate = Date()
                            onApply()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPresented = false }
                        }
                    }
                    HStack(spacing: 8) {
                        sheetPresetButton("7 dias", active: is7DaysPreset) {
                            startDate = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: Date())) ?? Date()
                            endDate = Date()
                            onApply()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPresented = false }
                        }
                        sheetPresetButton("30 dias", active: is30DaysPreset) {
                            startDate = Calendar.current.date(byAdding: .day, value: -29, to: Calendar.current.startOfDay(for: Date())) ?? Date()
                            endDate = Date()
                            onApply()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPresented = false }
                        }
                    }
                }
                
                // Date range
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("INÍCIO")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Theme.gold.opacity(0.7))
                        DatePicker("", selection: $startDate, in: ...endDate, displayedComponents: .date)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .tint(Theme.gold)
                            .scaleEffect(0.75, anchor: .leading)
                            .frame(width: 130, height: 30, alignment: .leading)
                            .clipped()
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.2))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("FIM")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Theme.gold.opacity(0.7))
                        DatePicker("", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .tint(Theme.gold)
                            .scaleEffect(0.75, anchor: .leading)
                            .frame(width: 130, height: 30, alignment: .leading)
                            .clipped()
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                }
                
                // Confirm
                Button(action: {
                    onApply()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPresented = false }
                }) {
                    Text("Aplicar Filtro")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 10)
                        .background(Theme.gold.opacity(0.25))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Theme.gold.opacity(0.4), lineWidth: 1))
                }
            }
            .padding(24)
            .background(
                ZStack {
                    Color(hex: "080B12")
                    LinearGradient(
                        colors: [Color(hex: "080B12"), Color(hex: "121624"), Color(hex: "1C2235")],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                    .blur(radius: 20)
                }
            )
            .cornerRadius(28)
            .shadow(color: .white.opacity(0.1), radius: 15, x: 0, y: 4)
            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 110)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - Sheet Preset Button
    private func sheetPresetButton(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(active ? .white : Theme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(active ? Theme.gold.opacity(0.3) : Color.white.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(active ? Theme.gold.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

#Preview {
    TransactionsView()
        .environmentObject(AuthService.shared)
}
