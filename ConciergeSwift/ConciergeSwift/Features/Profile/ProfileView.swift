//
//  ProfileView.swift
//  ConciergeSwift
//
//  User profile - Modern Design Pattern
//  Dark gradient header + Centered Avatar Card + Settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showLogoutAlert = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main Background
            Color(hex: "F8F9FA")
                .ignoresSafeArea()
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 0) {
                    // Spacer to push content down significantly (Top Padding for User)
                    Color.clear.frame(height: 60)
                    
                    // Profile Card
                    profileCard
                    
                    // Simplified Settings
                    settingsContent
                        .padding(.top, 24)
                        .padding(.bottom, 40) // Bottom padding for scroll
                }
            }
            .scrollIndicators(.hidden)
        }
        .alert("Sair da Conta", isPresented: $showLogoutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Sair", role: .destructive) {
                try? authService.signOut()
            }
        } message: {
            Text("Tem certeza que deseja sair?")
        }
    }
    
    // MARK: - Profile Card (Centered Avatar)
    private var profileCard: some View {
        VStack(spacing: 16) {
            // Avatar Container
            ZStack(alignment: .bottomTrailing) {
                // Main Avatar Box
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .overlay(
                        Image(systemName: "person")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(Theme.midnight.opacity(0.3))
                    )
                
                // Gold Badge
                ZStack {
                    Circle()
                        .fill(Theme.gold)
                        .frame(width: 32, height: 32)
                        .shadow(color: Theme.gold.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .offset(x: 8, y: 8)
            }
            
            // Name and Status
            VStack(spacing: 4) {
                Text(authService.currentUser?.displayName ?? "Usuário")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.midnight)
                
                Text("Membro Concierge Black")
                    .font(.subheadline)
                    .foregroundColor(Theme.gold)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Settings Content
    private var settingsContent: some View {
        VStack(spacing: 20) {
            // Account Section
            SettingsSection(title: "Conta") {
                SettingsRow(icon: "person", title: "Meus Dados", subtitle: "Editar informações pessoais")
                Divider().padding(.leading, 64)
                SettingsRow(icon: "creditcard", title: "Moeda", subtitle: "BRL - Real Brasileiro")
            }
            
            // Preferences Section
            SettingsSection(title: "Preferências") {
                SettingsRow(icon: "bell", title: "Notificações", subtitle: "Alertas e lembretes")
                Divider().padding(.leading, 64)
                SettingsRow(icon: "moon", title: "Aparência", subtitle: "Tema escuro ativado")
            }
            
            // Data Section
            SettingsSection(title: "Dados") {
                SettingsRow(icon: "arrow.down.doc", title: "Exportar Dados", subtitle: "Baixar em CSV")
                Divider().padding(.leading, 64)
                SettingsRow(icon: "shield", title: "Privacidade", subtitle: "Segurança e dados")
            }
            
            // Logout Button
            Button(action: { showLogoutAlert = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.body)
                        .foregroundColor(Theme.error)
                        .frame(width: 40, height: 40)
                        .background(Theme.error.opacity(0.1))
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
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
            
            // Version
            Text("Concierge Finance v1.0.0")
                .font(.caption)
                .foregroundColor(Theme.textTertiary)
                .padding(.top, 16)
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(Theme.midnight.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "F8F9FA"))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.midnight)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(12)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService.shared)
}
