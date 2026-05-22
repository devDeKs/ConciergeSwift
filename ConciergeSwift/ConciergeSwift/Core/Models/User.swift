//
//  User.swift
//  ConciergeSwift
//
//  User model
//

import Foundation
import FirebaseAuth

struct AppUser: Identifiable, Codable {
    let id: String
    let email: String
    let displayName: String?
    let createdAt: Date
    // MARK: - Concierge Black & Limits
    var isBlackMember: Bool
    var dailyAIMessageCount: Int
    var lastAIMessageDate: Date?
    
    init(from firebaseUser: FirebaseAuth.User, isBlack: Bool = false, msgCount: Int = 0, lastMsg: Date? = nil) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.displayName = firebaseUser.displayName
        self.createdAt = firebaseUser.metadata.creationDate ?? Date()
        self.isBlackMember = isBlack
        self.dailyAIMessageCount = msgCount
        self.lastAIMessageDate = lastMsg
    }
    
    init(id: String, email: String, displayName: String? = nil, createdAt: Date = Date(), isBlack: Bool = false, msgCount: Int = 0, lastMsg: Date? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
        self.isBlackMember = isBlack
        self.dailyAIMessageCount = msgCount
        self.lastAIMessageDate = lastMsg
    }
}
