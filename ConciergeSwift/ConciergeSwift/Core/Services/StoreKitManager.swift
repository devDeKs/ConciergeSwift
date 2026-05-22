//
//  StoreKitManager.swift
//  ConciergeSwift
//
//  Handles Apple Pay Subscriptions via StoreKit 2
//

import StoreKit
import SwiftUI

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isPurchasing: Bool = false
    
    // Substitua pelos IDs reais criados no App Store Connect
    private let productIDs = ["com.concierge.black.monthly", "com.concierge.black.yearly"]
    
    private init() {
        Task {
            await fetchProducts()
            await updateCustomerProductStatus()
        }
    }
    
    func fetchProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        isPurchasing = true
        defer { isPurchasing = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            purchasedProductIDs.insert(transaction.productID)
            await transaction.finish()
            
            // Ativa o plano no banco de dados do usuário
            await activateBlackStatus()
            
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func updateCustomerProductStatus() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedProductIDs.insert(transaction.productID)
            } catch {
                print("Transaction failed verification")
            }
        }
        
        if !purchasedProductIDs.isEmpty {
            await activateBlackStatus()
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func activateBlackStatus() async {
        guard let user = AuthService.shared.currentUser else { return }
        
        do {
            try await FirestoreService.shared.updateUserProfile(userId: user.id, data: ["isBlackMember": true])
            await AuthService.shared.refreshUser()
        } catch {
            print("Erro ao ativar Black: \(error)")
        }
    }
    
    // MARK: - Simulador de Apple Pay para Desenvolvimento
    func simulateApplePay() async {
        isPurchasing = true
        // Simula o tempo de processamento do FaceID / Apple Pay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await activateBlackStatus()
        isPurchasing = false
    }
}

enum StoreError: Error {
    case failedVerification
}
