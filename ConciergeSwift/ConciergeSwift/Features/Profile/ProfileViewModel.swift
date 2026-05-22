//
//  ProfileViewModel.swift
//  ConciergeSwift
//
//  Manage profile stats and data
//

import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var transactionsCount: Int = 0
    @Published var debtsCount: Int = 0
    @Published var savingsAmount: Double = 0.0
    @Published var isLoading: Bool = false
    
    private let firestoreService = FirestoreService.shared
    
    var formattedSavings: String {
        return savingsAmount.formattedCurrency
    }
    
    func loadStats(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let transactions = try await firestoreService.fetchTransactions(userId: userId)
            let debts = try await firestoreService.fetchDebts(userId: userId)
            
            transactionsCount = transactions.count
            debtsCount = debts.count
            
            let income = transactions.filter({ $0.type == .income }).reduce(0) { $0 + $1.amount }
            let expense = transactions.filter({ $0.type == .expense }).reduce(0) { $0 + $1.amount }
            
            // Economia: Total Income minus Total Expenses
            savingsAmount = income - expense
        } catch {
            print("Error loading profile stats: \(error)")
        }
    }
}
