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
    private let usersCollection = "users"
    private let transactionsCollection = "transactions"
    private let debtsCollection = "debts"
    
    private init() {}
    
    // MARK: - User Profiles (Black & Limits)
    func fetchUserProfile(userId: String) async throws -> [String: Any]? {
        let doc = try await db.collection(usersCollection).document(userId).getDocument()
        return doc.data()
    }
    
    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        try await db.collection(usersCollection).document(userId).setData(data, merge: true)
    }
    
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
    
    // MARK: - Fetch Debts
    func fetchDebts(userId: String) async throws -> [Debt] {
        let snapshot = try await db.collection(debtsCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> Debt? in
            let data = document.data()
            guard let userId = data["userId"] as? String,
                  let description = data["description"] as? String,
                  let totalAmount = (data["totalAmount"] as? NSNumber)?.doubleValue,
                  let monthlyInstallment = (data["monthlyInstallment"] as? NSNumber)?.doubleValue,
                  let totalInstallments = data["totalInstallments"] as? Int,
                  let currentInstallment = data["currentInstallment"] as? Int,
                  let dueDay = data["dueDay"] as? Int,
                  let category = data["category"] as? String,
                  let statusStr = data["status"] as? String,
                  let status = DebtStatus(rawValue: statusStr) else {
                print("⚠️ Firestore debt decode skip for doc \(document.documentID)")
                return nil
            }
            
            let createdAt: Date
            if let timestamp = data["createdAt"] as? Timestamp {
                createdAt = timestamp.dateValue()
            } else {
                createdAt = Date()
            }
            
            return Debt(
                id: document.documentID,
                userId: userId,
                description: description,
                totalAmount: totalAmount,
                monthlyInstallment: monthlyInstallment,
                totalInstallments: totalInstallments,
                currentInstallment: currentInstallment,
                dueDay: dueDay,
                category: category,
                status: status,
                createdAt: createdAt
            )
        }
    }
    
    // MARK: - Add Debt
    func addDebt(_ debt: Debt) async throws {
        let data: [String: Any] = [
            "userId": debt.userId,
            "description": debt.description,
            "totalAmount": debt.totalAmount,
            "monthlyInstallment": debt.monthlyInstallment,
            "totalInstallments": debt.totalInstallments,
            "currentInstallment": debt.currentInstallment,
            "dueDay": debt.dueDay,
            "category": debt.category,
            "status": debt.status.rawValue,
            "createdAt": Timestamp(date: debt.createdAt)
        ]
        
        try await db.collection(debtsCollection).addDocument(data: data)
    }
    
    // MARK: - Delete Debt
    func deleteDebt(id: String) async throws {
        try await db.collection(debtsCollection).document(id).delete()
    }
    
    // MARK: - Pay Installment
    func payInstallment(debtId: String) async throws {
        let docRef = db.collection(debtsCollection).document(debtId)
        let document = try await docRef.getDocument()
        
        guard let data = document.data(),
              let current = data["currentInstallment"] as? Int,
              let total = data["totalInstallments"] as? Int else {
            return
        }
        
        let newCurrent = current + 1
        var updates: [String: Any] = ["currentInstallment": newCurrent]
        
        if newCurrent >= total {
            updates["status"] = DebtStatus.paid.rawValue
        }
        
        try await docRef.updateData(updates)
    }
    
    // MARK: - Debts Context String for AI
    func getDebtsContextString(userId: String) async -> String {
        do {
            let debts = try await fetchDebts(userId: userId)
            let activeDebts = debts.filter { $0.status == .active && !$0.isFullyPaid }
            
            if activeDebts.isEmpty {
                return "[DIVIDAS: Nenhuma dívida/parcelamento ativo.]"
            }
            
            let calendar = Calendar.current
            let now = Date()
            let today = calendar.component(.day, from: now)
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            let daysRemaining = max(1, daysInMonth - today)
            
            var totalPendingThisMonth: Double = 0
            var debtDetails: [String] = []
            
            for debt in activeDebts {
                let isPending = debt.isPendingThisMonth
                if isPending {
                    totalPendingThisMonth += debt.monthlyInstallment
                }
                let statusText = isPending ? "PENDENTE (vence dia \(debt.dueDay))" : "JÁ PAGA este mês"
                debtDetails.append("\(debt.description): \(debt.formattedInstallment)/mês (\(debt.currentInstallment)/\(debt.totalInstallments) parcelas) - \(statusText)")
            }
            
            let detailsStr = debtDetails.joined(separator: " | ")
            
            return "[DIVIDAS_MES: Total pendente este mês: R$ \(String(format: "%.2f", totalPendingThisMonth)) | Dias restantes no mês: \(daysRemaining) | Detalhes: \(detailsStr)]"
        } catch {
            return ""
        }
    }
}
