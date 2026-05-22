//
//  ConciergeSwiftApp.swift
//  ConciergeSwift
//
//  Main App Entry Point
//

import SwiftUI
import FirebaseCore

@main
struct ConciergeSwiftApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService.shared
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    SplashView()
                } else if authService.currentUser != nil {
                    MainTabView()
                        .environmentObject(authService)
                        .environmentObject(appState)
                } else {
                    AuthView()
                        .environmentObject(authService)
                }
            }
            // No forced color scheme - let views handle their own
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.midnight
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.gold)
                
                Text("Concierge")
                    .font(.custom("Georgia", size: 32))
                    .foregroundColor(Theme.gold)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.gold))
                    .padding(.top, 24)
            }
        }
    }
}

// MARK: - Currency Management
enum AppCurrency: String, CaseIterable, Identifiable {
    case brl = "BRL"
    case usd = "USD"
    
    var id: String { self.rawValue }
    
    var symbol: String {
        switch self {
        case .brl: return "R$"
        case .usd: return "$"
        }
    }
    
    var localeIdentifier: String {
        switch self {
        case .brl: return "pt_BR"
        case .usd: return "en_US"
        }
    }
    
    var displayName: String {
        switch self {
        case .brl: return "BRL - Real Brasileiro"
        case .usd: return "USD - Dólar Americano"
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var pendingChatMessage: String? = nil
    @Published var shouldFocusChatInput: Bool = false
    @Published var hideTabBar: Bool = false
    
    @AppStorage("appCurrency") var currentCurrencyRaw: String = AppCurrency.brl.rawValue
    
    var currentCurrency: AppCurrency {
        AppCurrency(rawValue: currentCurrencyRaw) ?? .brl
    }
}

// MARK: - Global Formatting Extensions
extension Double {
    var formattedCurrency: String {
        let raw = UserDefaults.standard.string(forKey: "appCurrency") ?? "BRL"
        let currency = AppCurrency(rawValue: raw) ?? .brl
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: currency.localeIdentifier)
        return formatter.string(from: NSNumber(value: self)) ?? "\(currency.symbol) 0,00"
    }
    
    var formattedCurrencyShort: String {
        let raw = UserDefaults.standard.string(forKey: "appCurrency") ?? "BRL"
        let currency = AppCurrency(rawValue: raw) ?? .brl
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: currency.localeIdentifier)
        
        let absValue = abs(self)
        if absValue >= 1_000_000 {
            formatter.positiveSuffix = "mi"
            formatter.negativeSuffix = "mi"
            formatter.maximumFractionDigits = 1
            return formatter.string(from: NSNumber(value: self / 1_000_000)) ?? "\(currency.symbol)0mi"
        } else if absValue >= 1_000 {
            formatter.positiveSuffix = "k"
            formatter.negativeSuffix = "k"
            formatter.maximumFractionDigits = 1
            return formatter.string(from: NSNumber(value: self / 1_000)) ?? "\(currency.symbol)0k"
        } else {
            return formatter.string(from: NSNumber(value: self)) ?? "\(currency.symbol)0"
        }
    }
}
