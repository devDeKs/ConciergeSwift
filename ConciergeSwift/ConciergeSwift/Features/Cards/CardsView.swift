//
//  CardsView.swift
//  ConciergeSwift
//
//  Credit cards / Installments - Fully Functional
//  Dark header + Light content
//

import SwiftUI

struct CardsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = CardsViewModel()
    @State private var showNewDebtModal = false
    
    @State private var showBlackPopup = false
    @State private var showPaywall = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Theme.background
                .ignoresSafeArea()
            
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "080B12"),
                        Color(hex: "121624"),
                        Color(hex: "1C2235")
                    ],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
                
                MinimalistPatternView()
            }
            .frame(height: 320)
            .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 0) {
                darkHeader
                lightContent
            }
            
        }
        .onAppear {
            if let userId = authService.currentUser?.id {
                Task { await viewModel.loadDebts(userId: userId) }
            }
        }
        .overlay {
            if showNewDebtModal {
                NewDebtView(isPresented: $showNewDebtModal) {
                    if let userId = authService.currentUser?.id {
                        Task { await viewModel.loadDebts(userId: userId) }
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showNewDebtModal)
        .overlay {
            if showBlackPopup {
                BlackFeaturePopup(isPresented: $showBlackPopup) {
                    showPaywall = true
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            ConciergeBlackView()
        }
    }
    
    // MARK: - Dark Header
    private var darkHeader: some View {
        VStack(spacing: 16) {
            Text("Cartões")
                .font(.custom("Georgia", size: 28))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.4), radius: 8, x: 0, y: 0)
                .padding(.top, 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Total em parcelas este mês")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                
                Text(viewModel.formattedMonthlyTotal)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(viewModel.activeDebts.count) parcelamento\(viewModel.activeDebts.count != 1 ? "s" : "") ativo\(viewModel.activeDebts.count != 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Light Content
    private var lightContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Parcelamentos")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        guard let user = authService.currentUser else { return }
                        if !user.isBlackMember && viewModel.activeDebts.count >= 2 {
                            withAnimation { showBlackPopup = true }
                        } else {
                            withAnimation { showNewDebtModal = true }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.caption)
                            Text("Novo")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Theme.gold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.gold.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.gold))
                        Spacer()
                    }
                    .padding(.vertical, 32)
                } else if viewModel.activeDebts.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.activeDebts) { debt in
                        DebtCard(debt: debt, onPay: {
                            guard let debtId = debt.id, let userId = authService.currentUser?.id else { return }
                            Task {
                                await viewModel.payInstallment(debtId: debtId, userId: userId)
                            }
                        }, onAdvance: {
                            guard let debtId = debt.id, let userId = authService.currentUser?.id else { return }
                            Task {
                                await viewModel.payInstallment(debtId: debtId, userId: userId)
                            }
                        }, onDelete: {
                            guard let debtId = debt.id, let userId = authService.currentUser?.id else { return }
                            Task {
                                await viewModel.deleteDebt(debtId: debtId, userId: userId)
                            }
                        })
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 100)
        }
        .background(Theme.background)
        .clipShape(RoundedCorner(radius: 36, corners: [.topLeft, .topRight]))
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: -8)
        .offset(y: -16)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.surfaceHover)
                    .frame(width: 64, height: 64)
                
                Image(systemName: "creditcard")
                    .font(.title2)
                    .foregroundColor(Theme.textTertiary)
            }
            
            Text("Nenhum parcelamento")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            
            Text("Adicione suas compras parceladas")
                .font(.caption)
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Debt Card
struct DebtCard: View {
    let debt: Debt
    let onPay: () -> Void
    let onAdvance: () -> Void
    let onDelete: () -> Void
    @State private var showActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.midnight.opacity(0.05))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "creditcard")
                            .font(.body)
                            .foregroundColor(Theme.midnight)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(debt.description)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(debt.category)
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: { withAnimation { showActions.toggle() } }) {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(Theme.textTertiary)
                        .padding(8)
                }
            }
            
            // Progress bar
            VStack(spacing: 4) {
                HStack {
                    Text("\(debt.currentInstallment) de \(debt.totalInstallments) parcelas")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(debt.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.gold)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.surfaceHover)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.gold)
                            .frame(width: geometry.size.width * debt.progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // Amount info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Parcela mensal")
                        .font(.caption)
                        .foregroundColor(Theme.textTertiary)
                    Text(debt.formattedInstallment)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Restante")
                        .font(.caption)
                        .foregroundColor(Theme.textTertiary)
                    Text(debt.formattedRemaining)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.error)
                }
            }
            
            // Due day badge
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textTertiary)
                Text("Vence todo dia \(debt.dueDay)")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                if debt.isPendingThisMonth {
                    Text("PENDENTE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.error)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.error.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Text("PAGA")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.success.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            
            // Action buttons
            if showActions {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if debt.isPendingThisMonth {
                            Button(action: onPay) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                    Text("Pagar Parcela")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Theme.success)
                                .cornerRadius(8)
                            }
                        }
                        
                        Button(action: onAdvance) {
                            HStack(spacing: 4) {
                                Image(systemName: "forward.fill")
                                    .font(.caption)
                                Text("Adiantar Parcela")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(Theme.gold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.gold.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Button(action: onDelete) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                Text("Remover")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(Theme.error)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.error.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Theme.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.surfaceHover, lineWidth: 1)
        )
    }
}

// MARK: - New Debt Modal (Dark Theme, fully functional)
struct NewDebtView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    var onSaved: () -> Void
    
    @State private var description: String = ""
    @State private var monthlyAmountText: String = ""
    @State private var installmentsText: String = ""
    @State private var dueDay: Int = 10
    @State private var selectedCategory: String = "Geral"
    @State private var isLoading = false
    
    let categories = ["Geral", "Alimentação", "Transporte", "Moradia", "Lazer", "Saúde", "Educação", "Compras", "Eletrônicos"]
    let dueDays = Array(1...28)
    
    var monthlyInstallment: Double {
        Double(monthlyAmountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
    
    var totalInstallments: Int {
        Int(installmentsText) ?? 0
    }
    
    var totalAmount: Double {
        monthlyInstallment * Double(totalInstallments)
    }
    
    var isFormValid: Bool {
        !description.isEmpty && totalAmount > 0 && totalInstallments > 0
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
                    Text("Nova Dívida")
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
                
                // Form Fields
                VStack(spacing: 16) {
                    // Description
                    VStack(alignment: .leading, spacing: 5) {
                        Text("DESCRIÇÃO")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Theme.gold.opacity(0.7))
                        
                        TextField("Ex: iPhone 15, Geladeira...", text: $description)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    HStack(spacing: 12) {
                        // Installment Value
                        VStack(alignment: .leading, spacing: 5) {
                            Text("VALOR DA PARCELA")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(Theme.gold.opacity(0.7))
                            
                            HStack {
                                Text("R$")
                                    .foregroundColor(.white.opacity(0.4))
                                TextField("0,00", text: $monthlyAmountText)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                                    .onChange(of: monthlyAmountText) { _, newValue in
                                        formatCurrencyInput(newValue)
                                    }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        
                        // Number of Installments
                        VStack(alignment: .leading, spacing: 5) {
                            Text("PARCELAS")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(Theme.gold.opacity(0.7))
                            
                            HStack {
                                Image(systemName: "number")
                                    .foregroundColor(.white.opacity(0.4))
                                TextField("12", text: $installmentsText)
                                    .keyboardType(.numberPad)
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                    }
                    
                    // Total preview
                    if totalAmount > 0 {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.gold)
                            Text("Valor Total:")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(formatCurrency(totalAmount))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.gold)
                        }
                        .padding(12)
                        .background(Theme.gold.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.gold.opacity(0.3), lineWidth: 1))
                    }
                    
                    HStack(spacing: 12) {
                        // Due Day
                        VStack(alignment: .leading, spacing: 5) {
                            Text("VENCIMENTO (DIA)")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(Theme.gold.opacity(0.7))
                            
                            Menu {
                                ForEach(dueDays, id: \.self) { day in
                                    Button("Dia \(day)") { dueDay = day }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("\(dueDay)")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.2))
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 5) {
                            Text("CATEGORIA")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(Theme.gold.opacity(0.7))
                            
                            Menu {
                                ForEach(categories, id: \.self) { category in
                                    Button(category) { selectedCategory = category }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.white.opacity(0.4))
                                    Text(selectedCategory)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.2))
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                        }
                    }
                }
                
                // Confirm Button
                Button(action: registerDebt) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Registrar Dívida")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.midnight)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .background(isFormValid ? Theme.gold : Theme.gold.opacity(0.4))
                .cornerRadius(14)
                .disabled(isLoading || !isFormValid)
                .padding(.top, 8)
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
    
    private func registerDebt() {
        guard let userId = authService.currentUser?.id else { return }
        isLoading = true
        
        let debt = Debt(
            userId: userId,
            description: description,
            totalAmount: totalAmount,
            monthlyInstallment: monthlyInstallment,
            totalInstallments: totalInstallments,
            currentInstallment: 0,
            dueDay: dueDay,
            category: selectedCategory,
            status: .active,
            createdAt: Date()
        )
        
        Task {
            do {
                try await FirestoreService.shared.addDebt(debt)
                await MainActor.run {
                    isLoading = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPresented = false }
                    onSaved()
                }
            } catch {
                print("❌ Error saving debt: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    private func formatCurrencyInput(_ newValue: String) {
        let numbersString = newValue.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let value = Double(numbersString) {
            let amount = value / 100
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            formatter.locale = Locale(identifier: "pt_BR")
            
            if let newString = formatter.string(from: NSNumber(value: amount)) {
                if monthlyAmountText != newString {
                    monthlyAmountText = newString
                }
            }
        } else {
            if monthlyAmountText != "" {
                monthlyAmountText = ""
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }
}

// MARK: - ViewModel
@MainActor
class CardsViewModel: ObservableObject {
    @Published var debts: [Debt] = []
    @Published var isLoading = false
    
    private let firestoreService = FirestoreService.shared
    
    var activeDebts: [Debt] {
        debts.filter { $0.status == .active && !$0.isFullyPaid }
    }
    
    var totalMonthly: Double {
        activeDebts.filter { $0.isPendingThisMonth }.reduce(0) { $0 + $1.monthlyInstallment }
    }
    
    var formattedMonthlyTotal: String {
        totalMonthly.formattedCurrency
    }
    
    func loadDebts(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            debts = try await firestoreService.fetchDebts(userId: userId)
        } catch {
            print("❌ Error loading debts: \(error)")
        }
    }
    
    func payInstallment(debtId: String, userId: String) async {
        do {
            try await firestoreService.payInstallment(debtId: debtId)
            await loadDebts(userId: userId)
        } catch {
            print("❌ Error paying installment: \(error)")
        }
    }
    
    func deleteDebt(debtId: String, userId: String) async {
        do {
            try await firestoreService.deleteDebt(id: debtId)
            await loadDebts(userId: userId)
        } catch {
            print("❌ Error deleting debt: \(error)")
        }
    }
}

#Preview {
    CardsView()
        .environmentObject(AuthService.shared)
}
