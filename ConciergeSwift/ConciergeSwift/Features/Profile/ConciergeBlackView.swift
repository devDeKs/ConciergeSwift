//
//  ConciergeBlackView.swift
//  ConciergeSwift
//
//  Premium Subscription Paywall and Alert Popup
//

import SwiftUI
import StoreKit

// MARK: - Paywall View
struct ConciergeBlackView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var storeManager = StoreKitManager.shared
    
    var body: some View {
        ZStack {
            // Fundo escuro premium
            LinearGradient(
                colors: [Color(hex: "020410"), Color(hex: "0A0E1A")],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // Ícone e Título
                        VStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 64))
                                .foregroundColor(Theme.gold)
                                .shadow(color: Theme.gold.opacity(0.5), radius: 20, x: 0, y: 10)
                            
                            Text("Concierge Black")
                                .font(.custom("Georgia", size: 36))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("A inteligência financeira da elite, ilimitada.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        // Funcionalidades
                        VStack(spacing: 24) {
                            FeatureRow(icon: "sparkles.rectangle.stack.fill", title: "IA Ilimitada", desc: "Consultor financeiro virtual 24h por dia.")
                            FeatureRow(icon: "doc.text.magnifyingglass", title: "Extrato Inteligente", desc: "Exporte análises em CSV mastigadas pela IA.")
                            FeatureRow(icon: "creditcard.fill", title: "Cartões Infinitos", desc: "Gestão ilimitada de faturas e cartões.")
                            FeatureRow(icon: "lock.shield.fill", title: "Posso Gastar Hoje?", desc: "Análise avançada antes de comprar.")
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 32)
                        
                        // Botão Apple Pay
                        Button(action: {
                            Task {
                                await storeManager.simulateApplePay()
                                dismiss()
                            }
                        }) {
                            HStack {
                                if storeManager.isPurchasing {
                                    ProgressView().tint(Theme.midnight)
                                } else {
                                    Image(systemName: "applelogo")
                                    Text("Assinar com Apple Pay")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(Theme.midnight)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.gold)
                            .cornerRadius(16)
                            .shadow(color: Theme.gold.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 24)
                        .disabled(storeManager.isPurchasing)
                        
                        Text("Plano de simulação ativado no ambiente de desenvolvimento.")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.gold.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Theme.gold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

// MARK: - Black Feature Popup Animado (Simplificado)
struct BlackFeaturePopup: View {
    @Binding var isPresented: Bool
    var onSubscribe: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }
            
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.gold)
                    .padding(.top, 10)
                
                Text("Função Exclusiva!")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.textPrimary)
                
                Text("Você descobriu uma função Black! 💎 A IA analisa todo o seu dinheiro e diz na hora se é saudável você gastar esse valor hoje. Assine o Concierge Black para liberar.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 10)
                
                VStack(spacing: 12) {
                    Button(action: {
                        isPresented = false
                        onSubscribe()
                    }) {
                        Text("Ver Plano Black")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.gold)
                            .cornerRadius(12)
                    }
                    
                    Button("Agora não") {
                        isPresented = false
                    }
                    .font(.subheadline)
                    .foregroundColor(Theme.textTertiary)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
            .scaleEffect(isPresented ? 1 : 0.8)
            .opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPresented)
        }
    }
}
