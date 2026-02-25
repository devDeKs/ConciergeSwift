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

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var pendingChatMessage: String? = nil
    @Published var shouldFocusChatInput: Bool = false
}
