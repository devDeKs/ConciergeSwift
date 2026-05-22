//
//  EditProfileView.swift
//  ConciergeSwift
//
//  Allows the user to update their Name, Email, and Password through sub-pages.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationStack {
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
                        
                        Text("Meus Dados")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    
                    // Menu Content
                    VStack(spacing: 16) {
                        NavigationLink(destination: EditNameView()) {
                            profileMenuRow(icon: "person.text.rectangle", title: "Alterar Nome")
                        }
                        
                        NavigationLink(destination: EditEmailView()) {
                            profileMenuRow(icon: "envelope", title: "Alterar E-mail")
                        }
                        
                        NavigationLink(destination: EditPasswordView()) {
                            profileMenuRow(icon: "lock.shield", title: "Alterar Senha")
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func profileMenuRow(icon: String, title: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.gold.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.gold)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(16)
        .background(Theme.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.borderLight, lineWidth: 1)
        )
    }
}

// MARK: - Edit Name View
struct EditNameView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var name: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Custom Header
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
                    Text("Alterar Nome").font(.headline).foregroundColor(Theme.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Como devemos te chamar?")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    TextField("Seu nome", text: $name)
                        .foregroundColor(Theme.textPrimary)
                        .padding()
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.borderLight, lineWidth: 1))
                }
                
                Button(action: saveName) {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Salvar Nome")
                                .font(.subheadline).fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.gold)
                    .cornerRadius(16)
                }
                .disabled(isLoading || name.isEmpty)
                
                Spacer()
            }
            .padding(24)
        }
        .navigationBarHidden(true)
        .onAppear {
            if let user = authService.currentUser {
                name = user.displayName ?? ""
            }
        }
    }
    
    private func saveName() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.updateName(name)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Edit Email View
struct EditEmailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var email: String = ""
    @State private var currentPassword: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var isSuccess = false
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
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
                    Text("Alterar E-mail").font(.headline).foregroundColor(Theme.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                
                if isSuccess {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Theme.success)
                        Text("Verifique seu e-mail!")
                            .font(.title3).fontWeight(.bold).foregroundColor(Theme.textPrimary)
                        Text("Enviamos um link de confirmação para o novo e-mail. Por favor, acesse para finalizar a alteração.")
                            .font(.caption).multilineTextAlignment(.center).foregroundColor(Theme.textSecondary)
                    }
                    .padding()
                    Spacer()
                } else {
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(Theme.error)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.error.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Senha Atual (Segurança)")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        SecureField("Sua senha atual", text: $currentPassword)
                            .foregroundColor(Theme.textPrimary)
                            .padding()
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.borderLight, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Novo E-mail")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        TextField("exemplo@email.com", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(Theme.textPrimary)
                            .padding()
                            .background(Theme.surface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.borderLight, lineWidth: 1))
                    }
                    
                    Button(action: saveEmail) {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Enviar Confirmação")
                                    .font(.subheadline).fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.gold)
                        .cornerRadius(16)
                    }
                    .disabled(isLoading || email.isEmpty || currentPassword.isEmpty)
                    
                    Spacer()
                }
            }
            .padding(24)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Leave email field blank
        }
    }
    
    private func saveEmail() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.reauthenticate(password: currentPassword)
                try await authService.updateEmail(email)
                isSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Edit Password View
struct EditPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var isPasswordStrong: Bool {
        guard newPassword.count >= 8 else { return false }
        let specialCharRegEx = ".*[!@#$%^&*()_+{}|:\"<>?~`-].*"
        let predicate = NSPredicate(format:"SELF MATCHES %@", specialCharRegEx)
        return predicate.evaluate(with: newPassword)
    }
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
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
                    Text("Alterar Senha").font(.headline).foregroundColor(Theme.textPrimary)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Senha Atual")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    SecureField("Sua senha antiga", text: $currentPassword)
                        .foregroundColor(Theme.textPrimary)
                        .padding()
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.borderLight, lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nova Senha")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    SecureField("Digite a nova senha", text: $newPassword)
                        .foregroundColor(Theme.textPrimary)
                        .padding()
                        .background(Theme.surface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.borderLight, lineWidth: 1))
                    
                    // Hints
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: newPassword.count >= 8 ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(newPassword.count >= 8 ? Theme.success : Theme.textTertiary)
                            Text("Mínimo de 8 caracteres")
                                .font(.caption2)
                                .foregroundColor(newPassword.count >= 8 ? Theme.textPrimary : Theme.textTertiary)
                        }
                        HStack {
                            Image(systemName: isPasswordStrong && newPassword.count > 0 ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isPasswordStrong && newPassword.count > 0 ? Theme.success : Theme.textTertiary)
                            Text("Pelo menos 1 caractere especial (!@#$%)")
                                .font(.caption2)
                                .foregroundColor(isPasswordStrong && newPassword.count > 0 ? Theme.textPrimary : Theme.textTertiary)
                        }
                    }
                    .padding(.top, 4)
                }
                
                Button(action: savePassword) {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Atualizar Senha")
                                .font(.subheadline).fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.gold)
                    .cornerRadius(16)
                }
                .disabled(isLoading || currentPassword.isEmpty || !isPasswordStrong)
                
                Spacer()
            }
            .padding(24)
        }
        .navigationBarHidden(true)
    }
    
    private func savePassword() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.reauthenticate(password: currentPassword)
                try await authService.updatePassword(newPassword)
                dismiss() // Ou pode exibir uma tela de sucesso
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
