//
//  AppNotification.swift
//  ConciergeSwift
//
//  In-app notification model with Firestore persistence
//

import Foundation
import FirebaseFirestore

enum NotificationType: String, Codable, CaseIterable {
    case debt = "debt"
    case spending = "spending"
    case insight = "insight"
    case crm = "crm"
    case system = "system"
    
    var icon: String {
        switch self {
        case .debt: return "creditcard.fill"
        case .spending: return "chart.bar.fill"
        case .insight: return "sparkles"
        case .crm: return "megaphone.fill"
        case .system: return "gearshape.fill"
        }
    }
    
    var label: String {
        switch self {
        case .debt: return "Dívida"
        case .spending: return "Gastos"
        case .insight: return "Insight"
        case .crm: return "Novidade"
        case .system: return "Sistema"
        }
    }
}

struct AppNotification: Identifiable {
    var id: String?
    let userId: String
    let type: NotificationType
    let title: String
    let body: String
    var isRead: Bool
    let createdAt: Date
    let metadata: [String: String]?
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
