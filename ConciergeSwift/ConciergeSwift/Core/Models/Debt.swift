//
//  Debt.swift
//  ConciergeSwift
//
//  Debt/installment model for credit card tracking
//

import Foundation
import FirebaseFirestore

enum DebtStatus: String, Codable, CaseIterable {
    case active = "active"
    case paid = "paid"
    
    var displayName: String {
        switch self {
        case .active: return "Ativo"
        case .paid: return "Quitado"
        }
    }
}

struct Debt: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let description: String
    let totalAmount: Double
    let monthlyInstallment: Double
    let totalInstallments: Int
    var currentInstallment: Int
    let dueDay: Int // Day of month (1-31)
    let category: String
    let status: DebtStatus
    let createdAt: Date
    
    var progress: Double {
        Double(currentInstallment) / Double(totalInstallments)
    }
    
    var remainingAmount: Double {
        let remaining = totalInstallments - currentInstallment
        return Double(remaining) * monthlyInstallment
    }
    
    var remainingInstallments: Int {
        totalInstallments - currentInstallment
    }
    
    var isFullyPaid: Bool {
        currentInstallment >= totalInstallments
    }
    
    /// Whether there's a pending payment this month
    var isPendingThisMonth: Bool {
        guard status == .active, !isFullyPaid else { return false }
        
        let cal = Calendar.current
        let components = cal.dateComponents([.month, .year], from: createdAt, to: Date())
        let monthsElapsed = (components.year ?? 0) * 12 + (components.month ?? 0)
        
        // If currentInstallment is less than or equal to monthsElapsed, 
        // they haven't paid the installment for the current month yet.
        return currentInstallment <= monthsElapsed
    }
    
    var formattedInstallment: String {
        monthlyInstallment.formattedCurrency
    }
    
    var formattedTotal: String {
        totalAmount.formattedCurrency
    }
    
    var formattedRemaining: String {
        remainingAmount.formattedCurrency
    }
}
