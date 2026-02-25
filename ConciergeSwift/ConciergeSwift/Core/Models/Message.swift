//
//  Message.swift
//  ConciergeSwift
//
//  Chat message model
//

import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct Message: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - API Message Format
struct APIMessage: Codable {
    let role: String
    let content: String
    
    init(from message: Message) {
        self.role = message.role.rawValue
        self.content = message.content
    }
}
