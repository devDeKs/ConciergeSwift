//
//  ProfileView.swift
//  ConciergeSwift
//
//  User profile and settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appState: AppState // for triggering language refresh implicitly 
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showLogoutAlert = false
    
    // Modals
    @State private var showEditProfile = false
    @State private var showCurrencySelection = false
    @State private var showExportData = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // White background
            Color.white
                .ignoresSafeArea()
            
            // Header Background (Midnight Blue with rounded bottom)
            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        colors: [Theme.midnight, Theme.midnightLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 260)
                .offset(y: -40) // Pushes top corners off-screen
                .ignoresSafeArea()
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 0) {
                // Header Title
                HStack {
                    Text("Perfil")
                        .font(.custom("Georgia", size: 28))
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.4), radius: 8, x: 0, y: 0)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        profileCard
                            .padding(.top, 32) // Overlap the header
                        
                        settingsContent
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100) // Space for TabBar
                }
            }
        }
        .alert("Sair", isPresented: $showLogoutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Sair", role: .destructive) {
                try? authService.signOut()
            }
        } message: {
            Text("Tem certeza que deseja sair?")
        }
        .onAppear {
            Task {
                await authService.refreshUser()
                if let userId = authService.currentUser?.id {
                    await viewModel.loadStats(userId: userId)
                }
            }
        }
        .sheet(isPresented: $showCurrencySelection) {
            CurrencySelectionView()
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showExportData) {
            ExportDataPopup()
        }
    }
    
    // MARK: - Profile Card (Floating white card)
    private var profileCard: some View {
        VStack(spacing: 20) {
            // User Info
            VStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Theme.surface)
                        .frame(width: 80, height: 80)
                    
                    Text(authService.currentUser?.displayName?.prefix(1).uppercased() ?? "U")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Theme.gold)
                }
                .overlay(
                    Circle()
                        .stroke(Theme.borderLight, lineWidth: 2)
                )
                
                Text(authService.currentUser?.displayName ?? "Usuário")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "0A0E1A"))
                
                Text(authService.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(Theme.textTertiary)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.gold)
                        .frame(width: 6, height: 6)
                    Text("Membro Concierge Black")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.gold)
                }
            }
            
            // Stats Row
            HStack(spacing: 0) {
                profileStat(value: "\(viewModel.transactionsCount)", label: "Transações", icon: "arrow.left.arrow.right")
                
                Rectangle()
                    .fill(Theme.borderLight)
                    .frame(width: 1, height: 36)
                
                profileStat(value: "\(viewModel.debtsCount)", label: "Dívidas", icon: "creditcard")
                
                Rectangle()
                    .fill(Theme.borderLight)
                    .frame(width: 1, height: 36)
                
                profileStat(value: viewModel.formattedSavings, label: "Economia", icon: "leaf")
            }
            .padding(.vertical, 12)
            .background(Theme.surface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.borderLight, lineWidth: 1)
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Theme.borderLight, lineWidth: 1)
        )
    }
    
    // MARK: - Profile Stat
    private func profileStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Theme.gold)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "0A0E1A"))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Settings Content
    private var settingsContent: some View {
        VStack(spacing: 20) {
            // Account Section
            LightSettingsSection(title: "Conta") {
                Button(action: { showEditProfile = true }) {
                    LightSettingsRow(icon: "person", title: "Meus Dados", subtitle: "Editar informações pessoais")
                }
                LightDivider()
                Button(action: { showCurrencySelection = true }) {
                    LightSettingsRow(icon: "creditcard", title: "Moeda", subtitle: "Definir moeda global")
                }
            }
            
            // Data Section
            LightSettingsSection(title: "Dados") {
                Button(action: { showExportData = true }) {
                    LightSettingsRow(icon: "arrow.down.doc", title: "Exportar Dados", subtitle: "Baixar em CSV")
                }
            }
            
            // Logout Button
            Button(action: { showLogoutAlert = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.body)
                        .foregroundColor(Theme.error)
                        .frame(width: 40, height: 40)
                        .background(Theme.errorBg)
                        .clipShape(Circle())
                    
                    Text("Sair da Conta")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.error)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Theme.textTertiary)
                }
                .padding(12)
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.error.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Components (Adapted for White background)
struct LightSettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.textTertiary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.borderLight, lineWidth: 1)
            )
        }
    }
}

struct LightSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    
    init(icon: String, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.gold)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "0A0E1A"))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(16)
    }
}

struct LightDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.borderLight)
            .frame(height: 1)
            .padding(.leading, 72)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService.shared)
        .environmentObject(AppState())
}
