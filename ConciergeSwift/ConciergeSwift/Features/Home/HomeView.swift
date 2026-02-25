//
//  HomeView.swift
//  ConciergeSwift
//
//  Home dashboard - Minimalist & Standardized Design
//  Predictable geometric patterns, refined sizes
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            // White background
            Theme.background
                .ignoresSafeArea()
            
            // Dark gradient section (same as balance card) with blur
            VStack(spacing: 0) {
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
                }
                .frame(height: 380)
                .clipShape(RoundedCorner(radius: 48, corners: [.bottomLeft, .bottomRight]))
            }
            .ignoresSafeArea(edges: .top)
            
            // Content
            VStack(spacing: 0) {
                // Safe area spacer
                Color.clear
                    .frame(height: 50)
                
                // Header
                header
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                
                // Balance Card
                balanceCard
                    .padding(.horizontal, 20)
                
                // AI Shortcuts
                shortcutsSection
                
                // Transactions Section
                transactionsSection
                    .padding(.top, 24)
            }
        }
        .task {
            if let userId = authService.currentUser?.id {
                await viewModel.loadData(userId: userId)
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(Theme.gold.opacity(0.8))
            }
            .frame(width: 40, height: 40)
            
            Spacer()
            
            Text("Concierge")
                .font(.custom("Georgia", size: 24))
                .foregroundColor(Theme.gold)
            
            Spacer()
            
            Button(action: {}) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "bell")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: -6, y: 6)
                }
            }
        }
    }
    
    // MARK: - Balance Card
    private var balanceCard: some View {
        ZStack {
            // Background with gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "080B12"),
                            Color(hex: "121624"),
                            Color(hex: "1C2235")
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
            
            // Minimalist Standardized Pattern
            MinimalistPatternView()
                .clipShape(RoundedRectangle(cornerRadius: 24))
            
            // Subtle Border
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.12)
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    ),
                    lineWidth: 1
                )
            
            // Content
            VStack(spacing: 0) {
                // Header row
                HStack(alignment: .top) {
                    Text("Disponível")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("SALDO")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Theme.gold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.gold.opacity(0.15))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                // Balance
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.formattedBalance)
                        .font(.system(size: 32, weight: .bold)) // Reduced size from 38 to 32
                        .foregroundColor(.white)
                    
                    HStack(spacing: 24) {
                        // Income
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.formattedIncome)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "00DC82"))
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: "102A24"))
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(Color(hex: "00DC82"))
                                    )
                                Text("Ganhos")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        // Expense
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.formattedExpense)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "FF4757"))
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: "2A1015"))
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Image(systemName: "arrow.down.left")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(Color(hex: "FF4757"))
                                    )
                                Text("Gastos")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Quick Actions
                HStack(spacing: 0) {
                    QuickActionButton(icon: "arrow.up.right", label: "Receita") {}
                    QuickActionButton(icon: "arrow.down.right", label: "Despesas") {}
                    QuickActionButton(icon: "creditcard", label: "Parcelas") {}
                    QuickActionButton(icon: "chart.bar", label: "Relatórios") {}
                }
                .padding(.bottom, 4)
            }
            .padding(24)
        }
        .frame(height: 260)
        .shadow(color: .black.opacity(0.5), radius: 25, x: 0, y: 15)
    }
    
    // MARK: - AI Shortcuts Section
    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.gold)
                Text("ATALHOS IA")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                    .tracking(1)
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                // Novo Registro Card
                Button(action: { 
                    appState.shouldFocusChatInput = true
                    appState.selectedTab = 2 
                }) {
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.gold.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.gold)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Novo Registro")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Falar com IA agora")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface) // Adaptive dark surface
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
                
                // Analise Mensal Card
                Button(action: { 
                    appState.pendingChatMessage = "Como estão meus gastos este mês?"
                    appState.selectedTab = 2
                }) {
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.surfaceHover)
                                .frame(width: 36, height: 36)
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Análise Mensal")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Como estou indo?")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 24)
    }
    
    // MARK: - Transactions Section
    private var transactionsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Transações")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button("Ver todas") {}
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.gold)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            if viewModel.recentTransactions.isEmpty {
                VStack(spacing: 8) {
                    Spacer().frame(height: 40)
                    Text("Nenhuma transação recente")
                        .font(.subheadline)
                        .foregroundColor(Theme.textTertiary)
                    Text("Use o chat para registrar gastos")
                        .font(.caption)
                        .foregroundColor(Theme.textTertiary.opacity(0.7))
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.recentTransactions) { transaction in
                            TransactionRow(transaction: transaction)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Minimalist Pattern View
struct MinimalistPatternView: View {
    var body: some View {
        Canvas { context, size in
            let lineWidth: CGFloat = 0.8
            
            // Standardized, predictable large circles/arcs
            let circleSize = size.height * 1.2
            
            // Grid of interacting circles creates a predictable geometric pattern
            let centers = [
                CGPoint(x: 0, y: 0),
                CGPoint(x: size.width, y: 0),
                CGPoint(x: 0, y: size.height),
                CGPoint(x: size.width, y: size.height),
                CGPoint(x: size.width/2, y: size.height/2)
            ]
            
            for center in centers {
                var path = Path()
                path.addEllipse(in: CGRect(
                    x: center.x - circleSize/2,
                    y: center.y - circleSize/2,
                    width: circleSize,
                    height: circleSize
                ))
                
                // Gradient stroke interaction
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: Theme.gold.opacity(0.0), location: 0),
                            .init(color: Theme.gold.opacity(0.1), location: 0.4),
                            .init(color: Theme.gold.opacity(0.2), location: 1)
                        ]),
                        startPoint: CGPoint(x: 0, y: size.height), // Darker bottom-left
                        endPoint: CGPoint(x: size.width, y: 0)     // Lighter top-right
                    ),
                    lineWidth: lineWidth
                )
            }
        }
    }
}

// MARK: - Quick Action Button (Smaller)
struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Theme.gold.opacity(0.4), lineWidth: 1)
                        .frame(width: 42, height: 42) // Reduced from 48
                    
                    Image(systemName: icon)
                        .font(.system(size: 15)) // Reduced from 17
                        .foregroundColor(Theme.gold)
                }
                
                Text(label)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(transaction.type == .income ? Theme.success.opacity(0.1) : Theme.error.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transaction.type == .income ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 14))
                    .foregroundColor(transaction.type == .income ? Theme.success : Theme.error)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.textPrimary)
                
                Text(transaction.category)
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
            }
            
            Spacer()
            
            Text((transaction.type == .income ? "+" : "-") + transaction.formattedAmount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.type == .income ? Theme.success : Theme.error)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Rounded Corner
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - ViewModel
@MainActor
class HomeViewModel: ObservableObject {
    @Published var income: Double = 0
    @Published var expense: Double = 0
    @Published var recentTransactions: [Transaction] = []
    @Published var isLoading = false
    
    private let firestoreService = FirestoreService.shared
    
    var balance: Double { income - expense }
    var formattedBalance: String { formatCurrency(balance) }
    var formattedIncome: String { formatCurrency(income) }
    var formattedExpense: String { formatCurrency(expense) }
    
    func loadData(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let summary = try await firestoreService.getBalanceSummary(userId: userId)
            income = summary.income
            expense = summary.expense
            recentTransactions = try await firestoreService.fetchTransactions(userId: userId)
            
            // Inject fake transactions if empty (or for demo)
            if recentTransactions.isEmpty {
                recentTransactions = [
                    Transaction(id: "1", userId: userId, type: .expense, amount: 1250.50, description: "Apple Store", category: "Compras", createdAt: Date()),
                    Transaction(id: "2", userId: userId, type: .expense, amount: 25.75, description: "Starbucks", category: "Alimentação", createdAt: Date().addingTimeInterval(-86400)),
                    Transaction(id: "3", userId: userId, type: .income, amount: 4500.00, description: "Salário Mensal", category: "Salário", createdAt: Date().addingTimeInterval(-172800)),
                    Transaction(id: "4", userId: userId, type: .expense, amount: 89.90, description: "Netflix", category: "Lazer", createdAt: Date().addingTimeInterval(-259200)),
                    Transaction(id: "5", userId: userId, type: .expense, amount: 35.00, description: "Uber Trip", category: "Transporte", createdAt: Date().addingTimeInterval(-345600))
                ]
            }
        } catch {
            print("Error loading home data: \(error)")
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }
    
    private func formatCurrencyShort(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0,00"
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService.shared)
}
