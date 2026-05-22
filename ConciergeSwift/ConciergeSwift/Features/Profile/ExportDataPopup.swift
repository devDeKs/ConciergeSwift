//
//  ExportDataPopup.swift
//  ConciergeSwift
//
//  Export CSV using AI to parse user transactions.
//

import SwiftUI

struct ExportDataPopup: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedPeriod: ExportPeriod = .allTime
    @State private var isExporting = false
    @State private var errorMessage: String? = nil
    @State private var csvURL: URL? = nil
    @State private var showShareSheet = false
    
    @State private var showBlackPopup = false
    @State private var showPaywall = false
    
    enum ExportPeriod: String, CaseIterable {
        case thisMonth = "Este Mês"
        case thisYear = "Este Ano"
        case allTime = "Tudo"
    }
    
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(Theme.surface)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Exportar Dados")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 48))
                                .foregroundColor(Theme.gold)
                                .padding(.bottom, 8)
                            
                            Text("Extrato Inteligente via IA")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textPrimary)
                            
                            Text("A Concierge AI vai analisar suas transações e gerar um relatório CSV detalhado perfeito para planilhas.")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 16)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Período")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Theme.textPrimary)
                            
                            HStack(spacing: 12) {
                                ForEach(ExportPeriod.allCases, id: \.self) { period in
                                    Button(action: { selectedPeriod = period }) {
                                        Text(period.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(selectedPeriod == period ? Theme.gold : Theme.surfaceHover)
                                            .foregroundColor(selectedPeriod == period ? .white : Theme.textPrimary)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(Theme.error)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Theme.error.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button(action: generateExport) {
                            HStack {
                                if isExporting {
                                    ProgressView().tint(.white)
                                    Text("A IA está digitando...")
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Gerar Arquivo CSV")
                                }
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.midnight)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isExporting)
                        
                    }
                    .padding(24)
                }
            }
            
            if showBlackPopup {
                BlackFeaturePopup(isPresented: $showBlackPopup) {
                    showPaywall = true
                }
                .zIndex(100)
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            ConciergeBlackView()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            if let url = csvURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private func generateExport() {
        guard let user = authService.currentUser else { return }
        
        if !user.isBlackMember {
            showBlackPopup = true
            return
        }
        
        isExporting = true
        errorMessage = nil
        
        Task {
            do {
                let allTransactions = try await FirestoreService.shared.fetchTransactions(userId: user.id)
                
                // Filter by period
                let filtered = allTransactions.filter { tx in
                    let calendar = Calendar.current
                    switch selectedPeriod {
                    case .thisMonth:
                        return calendar.isDate(tx.createdAt, equalTo: Date(), toGranularity: .month)
                    case .thisYear:
                        return calendar.isDate(tx.createdAt, equalTo: Date(), toGranularity: .year)
                    case .allTime:
                        return true
                    }
                }
                
                if filtered.isEmpty {
                    errorMessage = "Nenhuma transação encontrada no período selecionado."
                    isExporting = false
                    return
                }
                
                // Fetch AI CSV
                let csvString = try await AIService.shared.generateCSV(from: filtered)
                
                // Save to local file
                let fileName = "Concierge_Extrato_\(selectedPeriod.rawValue.replacingOccurrences(of: " ", with: "_")).csv"
                let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentDir.appendingPathComponent(fileName)
                
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                
                self.csvURL = fileURL
                self.showShareSheet = true
                
            } catch {
                errorMessage = "Falha ao gerar extrato: \(error.localizedDescription)"
            }
            
            isExporting = false
        }
    }
}

// MARK: - Share Sheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
