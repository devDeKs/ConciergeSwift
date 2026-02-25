//
//  MainTabView.swift
//  ConciergeSwift
//
//  Main tab bar navigation - 4 tabs as in original design
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    init() {
        // Hide standard tab bar to use custom one
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Home Tab
            HomeView()
                .tag(0)
            
            // Transactions Tab
            TransactionsView()
                .tag(1)
            
            // Chat Tab
            ChatView()
                .tag(2)
            
            // Cards Tab
            CardsView()
                .tag(3)
            
            // Profile Tab
            ProfileView()
                .tag(4)
        }
        .safeAreaInset(edge: .bottom) {
            CustomTabBar(selectedTab: $appState.selectedTab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    // Using functional tabs mapped to the image's aesthetic line-drawn icons
    let tabs: [(icon: String, selectedIcon: String, title: String)] = [
        ("house", "house.fill", "Início"),
        ("chart.pie", "chart.pie.fill", "Transações"),
        ("sparkles", "sparkles", "Chat"), 
        ("creditcard", "creditcard.fill", "Cartão"),
        ("person", "person.fill", "Perfil")
    ]
    
    let originalChatIcons = ("bubble.left.and.bubble.right", "bubble.left.and.bubble.right.fill", "Chat")
    
    // Helper to get tab data
    func getTab(at index: Int) -> (icon: String, selectedIcon: String, title: String) {
        if index == 2 {
            return originalChatIcons
        }
        if index == 1 {
            return ("chart.pie", "chart.pie.fill", "Transações") // Matches "Analytics" from image visually
        }
        return tabs[index]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                let tab = getTab(at: index)
                let isSelected = selectedTab == index
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                            .font(.system(size: 22, weight: isSelected ? .regular : .light))
                            .foregroundColor(isSelected ? Theme.gold : Theme.textTertiary)
                            .shadow(color: isSelected ? Theme.gold.opacity(0.6) : .clear, radius: isSelected ? 8 : 0)
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                        
                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? Theme.gold : Theme.textTertiary)
                            .shadow(color: isSelected ? Theme.gold.opacity(0.3) : .clear, radius: isSelected ? 4 : 0)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle()) // Make entire area tappable
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 10) // Small padding before safe area begins
        .background(
            Color.white
                .cornerRadius(24) // Applies to all, but bottom expands past safe area
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // Safely get bottom inset
    private var safeAreaBottom: CGFloat {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        let bottomPadding = window?.safeAreaInsets.bottom ?? 0
        return bottomPadding > 0 ? bottomPadding : 20
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService.shared)
}
