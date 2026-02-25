//
//  CardsView.swift
//  ConciergeSwift
//
//  Credit cards / Installments - Original Design Pattern
//  Dark header + Light content
//

import SwiftUI

struct CardsView: View {
    @State private var installments: [CardInstallment] = []
    @State private var isLoading = false
    @State private var showNewDebtModal = false
    
    var totalMonthly: Double {
        installments.reduce(0) { $0 + $1.installmentAmount }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Light global background
            Theme.background
                .ignoresSafeArea()
            
            // Dark Gradient Header Background (spans underneath the white overlapping content)
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
            .frame(height: 320) // Height increased slightly to safely cover the new padding
            .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 0) {
                // Dark Header
                darkHeader
                
                // Light Content
                lightContent
            }
            
            // Modal Overlay
            if showNewDebtModal {
                NewDebtView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
    }
    
    // MARK: - Dark Header
    private var darkHeader: some View {
        VStack(spacing: 16) {
            // Title
            Text("Cartões")
                .font(.custom("Georgia", size: 28))
                .foregroundColor(.white)
                .padding(.top, 16)
            
            // Monthly Total Card
            VStack(alignment: .leading, spacing: 4) {
                Text("Total em parcelas este mês")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                
                Text(formatCurrency(totalMonthly))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(installments.count) parcelamento\(installments.count != 1 ? "s" : "") ativo\(installments.count != 1 ? "s" : "")")
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
        .padding(.bottom, 40) // Increased padding to cleanly clear the white overlap
        // Background removed from here; it is now hosted cleanly at the ZStack root
    }
    
    // MARK: - Light Content
    private var lightContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Parcelamentos")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showNewDebtModal = true
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
                
                // Installments List
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.gold))
                        Spacer()
                    }
                    .padding(.vertical, 32)
                } else if installments.isEmpty {
                    emptyState
                } else {
                    ForEach(installments) { installment in
                        InstallmentCard(installment: installment)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 100)
        }
        .background(Theme.background)
        .clipShape(RoundedCorner(radius: 36, corners: [.topLeft, .topRight])) // Corner radius maior
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: -8) // Sombra suave apontando para cima
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
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }
}

// MARK: - Card Installment Model
struct CardInstallment: Identifiable {
    let id = UUID()
    let description: String
    let totalAmount: Double
    let installmentAmount: Double
    let currentInstallment: Int
    let totalInstallments: Int
    let dueDate: Date
    let cardName: String
    
    var progress: Double {
        Double(currentInstallment) / Double(totalInstallments)
    }
}

// MARK: - Installment Card
struct InstallmentCard: View {
    let installment: CardInstallment
    
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
                        Text(installment.description)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(installment.cardName)
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
            }
            
            // Progress bar
            VStack(spacing: 4) {
                HStack {
                    Text("\(installment.currentInstallment) de \(installment.totalInstallments) parcelas")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(installment.progress * 100))%")
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
                            .frame(width: geometry.size.width * installment.progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // Amount info
            HStack {
                Text("Próxima parcela:")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                Text(formatCurrency(installment.installmentAmount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .padding(16)
        .background(Theme.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4) // Added subtle shadow
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.surfaceHover, lineWidth: 1)
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }
}

#Preview {
    CardsView()
        .environmentObject(AuthService.shared)
}

// MARK: - New Debt Modal
struct NewDebtView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthService
    
    @State private var description: String = ""
    @State private var totalValue: Double = 0.0
    @State private var paidValue: Double = 0.0
    @State private var dueDate: Date = Date()
    @State private var selectedCategory: String = "Geral"
    @State private var isLoading = false
    
    let categories = ["Geral", "Alimentação", "Transporte", "Moradia", "Lazer", "Saúde"]
    
    var body: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
            
            // Modal Card
            VStack(spacing: 24) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.gold)
                            .padding(10)
                            .background(Theme.gold.opacity(0.1))
                            .clipShape(Circle())
                        
                        Text("Nova Dívida")
                            .font(.custom("Georgia", size: 20)) // Serif font as per header style
                            .bold()
                            .foregroundColor(Theme.midnight)
                    }
                    
                    Spacer()
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.textTertiary)
                            .padding(8)
                            .background(Color(hex: "F8F9FA"))
                            .clipShape(Circle())
                    }
                }
                
                // Form Fields
                VStack(spacing: 20) {
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("O QUE VOCÊ COMPROU?")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textSecondary)
                        
                        TextField("Ex: Novo Monitor", text: $description)
                            .padding()
                            .background(Color(hex: "F8F9FA"))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.gold.opacity(0.2), lineWidth: 1))
                    }
                    
                    HStack(spacing: 16) {
                        // Total Value
                        VStack(alignment: .leading, spacing: 8) {
                            Text("VALOR TOTAL")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textSecondary)
                            
                            CurrencyInputField(value: $totalValue)
                        }
                        
                        // Paid Value
                        VStack(alignment: .leading, spacing: 8) {
                            Text("JÁ PAGO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textSecondary)
                            
                            CurrencyInputField(value: $paidValue)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        // Due Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("VENCIMENTO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textSecondary)
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(Theme.textTertiary)
                                Text(formatDate(dueDate))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                            }
                            .padding()
                            .background(Color(hex: "F8F9FA"))
                            .cornerRadius(12)
                            .overlay(
                                DatePicker("", selection: $dueDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .opacity(0.015) // Invisible clickable overlay
                            )
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CATEGORIA")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textSecondary)
                            
                            Menu {
                                ForEach(categories, id: \.self) { category in
                                    Button(category) {
                                        selectedCategory = category
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(Theme.textTertiary)
                                    Text(selectedCategory)
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(hex: "F8F9FA"))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                
                // Action Button
                Button(action: registerDebt) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("REGISTRAR DÍVIDA")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.midnight)
                            .cornerRadius(16)
                    }
                }
                .disabled(isLoading || description.isEmpty || totalValue == 0)
                .opacity(description.isEmpty || totalValue == 0 ? 0.6 : 1.0)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(32)
            .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
            .padding(24)
        }
    }
    
    private func registerDebt() {
        // Implement logic to save debt
        // For now, just dismiss
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
}

// Helper for Currency Input
struct CurrencyInputField: View {
    @Binding var value: Double
    
    var body: some View {
        HStack {
            Text("R$")
                .foregroundColor(Theme.textTertiary)
            TextField("0,00", value: $value, format: .currency(code: "BRL"))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(hex: "F8F9FA"))
        .cornerRadius(12)
    }
}
