//
//  Transaction.swift
//  ConciergeSwift
//
//  Transaction model for income/expense tracking
//

import Foundation
import FirebaseFirestore
import SwiftUI

enum TransactionType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"
    
    var displayName: String {
        switch self {
        case .income: return "Receita"
        case .expense: return "Despesa"
        }
    }
    
    var icon: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
}

struct Transaction: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let type: TransactionType
    let amount: Double
    let description: String
    let category: String
    let createdAt: Date
    
    var formattedAmount: String {
        amount.formattedCurrency
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: createdAt)
    }
}

// MARK: - Transaction Categories
enum TransactionCategory: String, CaseIterable {
    case food = "Alimentação"
    case transport = "Transporte"
    case entertainment = "Lazer"
    case health = "Saúde"
    case education = "Educação"
    case shopping = "Compras"
    case bills = "Contas"
    case salary = "Salário"
    case investment = "Investimento"
    case other = "Outros"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .entertainment: return "gamecontroller.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .shopping: return "bag.fill"
        case .bills: return "doc.text.fill"
        case .salary: return "banknote.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return Color(hex: "FF6B6B")
        case .transport: return Color(hex: "4ECDC4")
        case .entertainment: return Color(hex: "45B7D1")
        case .health: return Color(hex: "FFBE76")
        case .education: return Color(hex: "A8E6CF")
        case .shopping: return Color(hex: "FF9FF3")
        case .bills: return Color(hex: "54A0FF")
        case .salary: return Color(hex: "5F27CD")
        case .investment: return Color(hex: "1DD1A1")
        case .other: return Color(hex: "8395A7")
        }
    }
}
