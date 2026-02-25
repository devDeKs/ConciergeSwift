//
//  TransactionsView.swift
//  ConciergeSwift
//
//  Transactions analysis with category chart
//

import SwiftUI
import Charts

struct TransactionsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var selectedPeriod: String = "Este mês"
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Theme.midnight.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    header
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView().tint(Theme.gold)
                        Spacer()
                    } else if viewModel.transactions.isEmpty {
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
                            VStack(spacing: 32) {
                                // Balance & Summary Cards
                                summaryCards
                                
                                // Timeline Statement
                                timeline
                            }
                            .padding(.top, 24)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .onAppear {
                guard let uid = authService.currentUser?.id else { return }
                Task {
                    await viewModel.loadTransactions(userId: uid)
                }
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Text("Transações")
                .font(.custom("Georgia", size: 32))
                .foregroundColor(.white)
            
            Spacer()
            
            Menu {
                Button("Este mês") { selectedPeriod = "Este mês" }
                Button("Mês passado") { selectedPeriod = "Mês passado" }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedPeriod)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(Theme.gold)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: 16) {
            // Income
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "1DD1A1"))
                    Text("ENTRADAS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Theme.textSecondary.opacity(0.7))
                }
                
                Text(viewModel.formatCurrency(viewModel.totalIncome))
                    .font(.custom("Georgia", size: 20))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.white.opacity(0.03))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            
            // Expense
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.gold)
                    Text("SAÍDAS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Theme.textSecondary.opacity(0.7))
                }
                
                Text(viewModel.formatCurrency(viewModel.totalExpense))
                    .font(.custom("Georgia", size: 20))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.white.opacity(0.03))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Timeline Statement
    private var timeline: some View {
        VStack(alignment: .leading, spacing: 28) {
            ForEach(viewModel.groupedTransactions, id: \.date) { group in
                VStack(alignment: .leading, spacing: 16) {
                    // Date Header
                    Text(group.date.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                        .padding(.horizontal, 24)
                    
                    // Transactions List
                    VStack(spacing: 4) {
                        ForEach(group.transactions) { transaction in
                            TransactionRowView(
                                transaction: transaction,
                                formattedAmount: viewModel.formatCurrency(transaction.amount)
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Transaction Row
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
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 48, height: 48)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 18))
                    .foregroundColor(isIncome ? Color(hex: "1DD1A1") : .white)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(transaction.description)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textTertiary)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text((isIncome ? "+ " : "- ") + formattedAmount)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isIncome ? Color(hex: "1DD1A1") : .white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.001)) // For tap target
    }
}

// MARK: - ViewModel
@MainActor
class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    
    // Financial Summaries
    @Published var totalIncome: Double = 0
    @Published var totalExpense: Double = 0
    
    var balance: Double {
        totalIncome - totalExpense
    }
    
    // Grouped for Timeline
    @Published var groupedTransactions: [(date: String, transactions: [Transaction])] = []
    
    private let firestoreService = FirestoreService.shared
    
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }
    
    func loadTransactions(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        print("🔍 Fetching for userId: \(userId)")
        
        do {
            let allTransactions = try await firestoreService.fetchTransactions(userId: userId)
            print("✅ Fetched \(allTransactions.count) transactions")
            
            // Sort by newest first
            self.transactions = allTransactions.sorted { $0.createdAt > $1.createdAt }
            
            // Calculate Totals
            self.totalIncome = self.transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            self.totalExpense = self.transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            // Group by Date for Timeline
            self.groupTransactionsByDate()
            
        } catch {
            print("❌ Error loading transactions: \(error)")
        }
    }
    
    private func groupTransactionsByDate() {
        let calendar = Calendar.current
        var grouped: [Date: [Transaction]] = [:]
        
        for transaction in transactions {
            let date = calendar.startOfDay(for: transaction.createdAt)
            grouped[date, default: []].append(transaction)
        }
        
        // Sort dates descending
        let sortedDates = grouped.keys.sorted(by: >)
        
        // Map to String tuples (Hoje, Ontem, etc)
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

#Preview {
    TransactionsView()
        .environmentObject(AuthService.shared)
}
