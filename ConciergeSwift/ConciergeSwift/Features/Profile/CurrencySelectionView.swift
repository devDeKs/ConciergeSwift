//
//  CurrencySelectionView.swift
//  ConciergeSwift
//
//  Select global currency (BRL or USD)
//

import SwiftUI

struct CurrencySelectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
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
                    
                    Text("Moeda")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(AppCurrency.allCases) { currency in
                            currencyRow(currency)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func currencyRow(_ currency: AppCurrency) -> some View {
        let isSelected = appState.currentCurrency == currency
        
        return Button(action: {
            withAnimation(.spring()) {
                appState.currentCurrencyRaw = currency.rawValue
            }
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.gold.opacity(0.15) : Theme.surfaceHover)
                        .frame(width: 48, height: 48)
                    
                    Text(currency.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? Theme.gold : Theme.textSecondary)
                }
                
                Text(currency.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.gold)
                }
            }
            .padding(16)
            .background(Theme.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Theme.gold.opacity(0.5) : Theme.borderLight, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}
