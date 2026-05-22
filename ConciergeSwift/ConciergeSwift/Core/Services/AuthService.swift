//
//  AuthService.swift
//  ConciergeSwift
//
//  Firebase Authentication service
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: AppUser?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    if let profile = try? await FirestoreService.shared.fetchUserProfile(userId: user.uid) {
                        let isBlack = profile["isBlackMember"] as? Bool ?? false
                        let msgCount = profile["dailyAIMessageCount"] as? Int ?? 0
                        let lastMsgDate = (profile["lastAIMessageDate"] as? Timestamp)?.dateValue()
                        
                        self?.currentUser = AppUser(from: user, isBlack: isBlack, msgCount: msgCount, lastMsg: lastMsgDate)
                    } else {
                        self?.currentUser = AppUser(from: user)
                    }
                } else {
                    self?.currentUser = nil
                }
                self?.isLoading = false
            }
        }
        
        // Fallback timeout
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            if isLoading {
                isLoading = false
            }
        }
    }
    
    // MARK: - Refresh
    func refreshUser() async {
        if let firebaseUser = Auth.auth().currentUser {
            do {
                try await firebaseUser.reload()
                let updatedUser = Auth.auth().currentUser!
                
                let profile = try? await FirestoreService.shared.fetchUserProfile(userId: updatedUser.uid)
                let isBlack = profile?["isBlackMember"] as? Bool ?? false
                let msgCount = profile?["dailyAIMessageCount"] as? Int ?? 0
                let lastMsgDate = (profile?["lastAIMessageDate"] as? Timestamp)?.dateValue()
                
                DispatchQueue.main.async {
                    self.currentUser = AppUser(from: updatedUser, isBlack: isBlack, msgCount: msgCount, lastMsg: lastMsgDate)
                }
            } catch {
                print("Failed to reload user: \(error)")
            }
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        errorMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput("Email e senha são obrigatórios")
        }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = AppUser(from: result.user)
        } catch let error as NSError {
            let message = mapFirebaseError(error)
            errorMessage = message
            throw AuthError.signInFailed(message)
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String) async throws {
        errorMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput("Email e senha são obrigatórios")
        }
        
        guard password.count >= 6 else {
            throw AuthError.invalidInput("Senha deve ter no mínimo 6 caracteres")
        }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            currentUser = AppUser(from: result.user)
        } catch let error as NSError {
            let message = mapFirebaseError(error)
            errorMessage = message
            throw AuthError.signUpFailed(message)
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            currentUser = nil
        } catch {
            throw AuthError.signOutFailed("Erro ao sair. Tente novamente.")
        }
    }
    // MARK: - Reauthentication
    func reauthenticate(password: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            throw AuthError.invalidInput("Não autenticado")
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        do {
            try await user.reauthenticate(with: credential)
        } catch let error as NSError {
            throw AuthError.invalidInput(mapFirebaseError(error))
        }
    }
    
    // MARK: - Update Profile
    func updateEmail(_ newEmail: String) async throws {
        guard let user = Auth.auth().currentUser else { throw AuthError.invalidInput("Não autenticado") }
        do {
            try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
        } catch let error as NSError {
            throw AuthError.invalidInput(mapFirebaseError(error))
        }
    }
    
    func updatePassword(_ newPass: String) async throws {
        guard let user = Auth.auth().currentUser else { throw AuthError.invalidInput("Não autenticado") }
        guard newPass.count >= 6 else { throw AuthError.invalidInput("Senha muito curta (mín. 6)") }
        do {
            try await user.updatePassword(to: newPass)
        } catch {
            throw AuthError.invalidInput("Falha ao atualizar senha. Faça login novamente e tente.")
        }
    }
    
    func updateName(_ newName: String) async throws {
        guard let user = Auth.auth().currentUser else { throw AuthError.invalidInput("Não autenticado") }
        let request = user.createProfileChangeRequest()
        request.displayName = newName
        do {
            try await request.commitChanges()
            self.currentUser = AppUser(from: user)
        } catch {
            throw AuthError.invalidInput("Falha ao atualizar nome.")
        }
    }
    
    
    // MARK: - Error Mapping
    private func mapFirebaseError(_ error: NSError) -> String {
        switch error.code {
        case AuthErrorCode.wrongPassword.rawValue, AuthErrorCode.invalidCredential.rawValue:
            return "A senha informada está incorreta."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Email inválido"
        case AuthErrorCode.userNotFound.rawValue:
            return "Usuário não encontrado"
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "Este email já está em uso"
        case AuthErrorCode.weakPassword.rawValue:
            return "Senha muito fraca"
        case AuthErrorCode.networkError.rawValue:
            return "Erro de conexão. Verifique sua internet."
        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidInput(String)
    case signInFailed(String)
    case signUpFailed(String)
    case signOutFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message),
             .signInFailed(let message),
             .signUpFailed(let message),
             .signOutFailed(let message):
            return message
        }
    }
}
