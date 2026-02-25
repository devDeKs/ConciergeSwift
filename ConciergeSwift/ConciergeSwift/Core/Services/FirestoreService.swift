//
//  FirestoreService.swift
//  ConciergeSwift
//
//  Firestore database service for transactions
//

import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    private let transactionsCollection = "transactions"
    
    private init() {}
    
    // MARK: - Fetch Transactions
    func fetchTransactions(userId: String) async throws -> [Transaction] {
        let snapshot = try await db.collection(transactionsCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> Transaction? in
            let data = document.data()
            guard let odUserId = data["userId"] as? String,
                  let typeStr = data["type"] as? String,
                  let type = TransactionType(rawValue: typeStr),
                  let amount = (data["amount"] as? NSNumber)?.doubleValue,
                  let description = data["description"] as? String,
                  let category = data["category"] as? String else {
                print("⚠️ Firestore decode skip for doc \(document.documentID)")
                return nil
            }
            
            // Handle Timestamp -> Date conversion
            let createdAt: Date
            if let timestamp = data["createdAt"] as? Timestamp {
                createdAt = timestamp.dateValue()
            } else {
                createdAt = Date()
            }
            
            return Transaction(
                id: document.documentID,
                userId: odUserId,
                type: type,
                amount: amount,
                description: description,
                category: category,
                createdAt: createdAt
            )
        }
    }
    
    // MARK: - Add Transaction
    func addTransaction(_ transaction: Transaction) async throws {
        let data: [String: Any] = [
            "userId": transaction.userId,
            "type": transaction.type.rawValue,
            "amount": transaction.amount,
            "description": transaction.description,
            "category": transaction.category,
            "createdAt": Timestamp(date: transaction.createdAt)
        ]
        
        try await db.collection(transactionsCollection).addDocument(data: data)
    }
    
    // MARK: - Delete Transaction
    func deleteTransaction(id: String) async throws {
        try await db.collection(transactionsCollection).document(id).delete()
    }
    
    // MARK: - Get Balance Summary
    func getBalanceSummary(userId: String) async throws -> (income: Double, expense: Double) {
        let transactions = try await fetchTransactions(userId: userId)
        
        let income = transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        let expense = transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        return (income, expense)
    }
    
    // MARK: - Get Monthly Context String for AI
    func getMonthlyContextString(userId: String) async -> String {
        do {
            let transactions = try await fetchTransactions(userId: userId)
            
            let calendar = Calendar.current
            let now = Date()
            
            let currentMonthTransactions = transactions.filter {
                calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month) &&
                calendar.isDate($0.createdAt, equalTo: now, toGranularity: .year)
            }
            
            if currentMonthTransactions.isEmpty {
                return "[CONTEXTO_FINANCEIRO: O usuário não possui transações registradas neste mês.]"
            }
            
            let income = currentMonthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = currentMonthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            var categoryTotals: [String: Double] = [:]
            for t in currentMonthTransactions where t.type == .expense {
                categoryTotals[t.category, default: 0] += t.amount
            }
            
            let sortedCategories = categoryTotals.sorted { $0.value > $1.value }.prefix(3)
            let categoriesString = sortedCategories.map { "\($0.key) (R$ \(String(format: "%.2f", $0.value)))" }.joined(separator: ", ")
            
            return "[CONTEXTO_FINANCEIRO: Mês Atual | Entradas: R$ \(String(format: "%.2f", income)) | Saídas: R$ \(String(format: "%.2f", expense)) | Top Categorias: \(categoriesString)]"
        } catch {
            return ""
        }
    }
}
