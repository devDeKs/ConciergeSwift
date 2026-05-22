//
//  NotificationService.swift
//  ConciergeSwift
//
//  Notification management with Firestore real-time listener
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    private let db = Firestore.firestore()
    private let collection = "notifications"
    private var listener: ListenerRegistration?
    
    private init() {}
    
    // MARK: - Real-time Listener
    func startListening(userId: String) {
        listener?.remove()
        
        listener = db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let documents = snapshot?.documents else {
                    if let error { print("❌ Notification listener error: \(error)") }
                    return
                }
                
                Task { @MainActor in
                    self.notifications = documents.compactMap { self.decode($0) }
                    self.unreadCount = self.notifications.filter { !$0.isRead }.count
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Decode
    private func decode(_ document: DocumentSnapshot) -> AppNotification? {
        let data = document.data() ?? [:]
        guard let userId = data["userId"] as? String,
              let typeStr = data["type"] as? String,
              let type = NotificationType(rawValue: typeStr),
              let title = data["title"] as? String,
              let body = data["body"] as? String else {
            return nil
        }
        
        let isRead = data["isRead"] as? Bool ?? false
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        let metadata = data["metadata"] as? [String: String]
        
        return AppNotification(
            id: document.documentID,
            userId: userId,
            type: type,
            title: title,
            body: body,
            isRead: isRead,
            createdAt: createdAt,
            metadata: metadata
        )
    }
    
    // MARK: - Create
    func createNotification(
        userId: String,
        type: NotificationType,
        title: String,
        body: String,
        metadata: [String: String]? = nil
    ) async {
        var data: [String: Any] = [
            "userId": userId,
            "type": type.rawValue,
            "title": title,
            "body": body,
            "isRead": false,
            "createdAt": Timestamp(date: Date())
        ]
        if let metadata { data["metadata"] = metadata }
        
        do {
            try await db.collection(collection).addDocument(data: data)
        } catch {
            print("❌ Error creating notification: \(error)")
        }
    }
    
    // MARK: - Mark as Read
    func markAsRead(_ notification: AppNotification) async {
        guard let id = notification.id else { return }
        do {
            try await db.collection(collection).document(id).updateData(["isRead": true])
        } catch {
            print("❌ Error marking as read: \(error)")
        }
    }
    
    func markAllAsRead(userId: String) async {
        let unread = notifications.filter { !$0.isRead }
        let batch = db.batch()
        
        for notification in unread {
            guard let id = notification.id else { continue }
            let ref = db.collection(collection).document(id)
            batch.updateData(["isRead": true], forDocument: ref)
        }
        
        do {
            try await batch.commit()
        } catch {
            print("❌ Error marking all as read: \(error)")
        }
    }
    
    // MARK: - Delete
    func deleteNotification(_ notification: AppNotification) async {
        guard let id = notification.id else { return }
        do {
            try await db.collection(collection).document(id).delete()
        } catch {
            print("❌ Error deleting notification: \(error)")
        }
    }
    
    // MARK: - Save FCM Token
    func saveFCMToken(_ token: String, userId: String) async {
        do {
            try await db.collection("users").document(userId).setData(
                ["fcmToken": token, "updatedAt": Timestamp(date: Date())],
                merge: true
            )
        } catch {
            print("❌ Error saving FCM token: \(error)")
        }
    }
}
