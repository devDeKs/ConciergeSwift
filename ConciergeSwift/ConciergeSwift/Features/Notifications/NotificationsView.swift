//
//  NotificationsView.swift
//  ConciergeSwift
//
//  Full-screen notifications - Dark gradient header + White content
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject var notificationService = NotificationService.shared
    @Environment(\.dismiss) private var dismiss
    
    private var groupedNotifications: [(String, [AppNotification])] {
        let calendar = Calendar.current
        let now = Date()
        
        var today: [AppNotification] = []
        var yesterday: [AppNotification] = []
        var thisWeek: [AppNotification] = []
        var older: [AppNotification] = []
        
        for n in notificationService.notifications {
            if calendar.isDateInToday(n.createdAt) {
                today.append(n)
            } else if calendar.isDateInYesterday(n.createdAt) {
                yesterday.append(n)
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
                      n.createdAt > weekAgo {
                thisWeek.append(n)
            } else {
                older.append(n)
            }
        }
        
        var groups: [(String, [AppNotification])] = []
        if !today.isEmpty { groups.append(("Hoje", today)) }
        if !yesterday.isEmpty { groups.append(("Ontem", yesterday)) }
        if !thisWeek.isEmpty { groups.append(("Esta Semana", thisWeek)) }
        if !older.isEmpty { groups.append(("Anteriores", older)) }
        return groups
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Light gray background (so white cards pop)
            Theme.surface
                .ignoresSafeArea()
            
            // 1. Content (Scrollable List)
            VStack(spacing: 0) {
                Color.clear.frame(height: 140) // Space for the header
                
                if notificationService.notifications.isEmpty {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .zIndex(0)
            
            // 2. Fixed Header layer
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    // Background
                    ZStack {
                        Color(hex: "080B12")
                        
                        LinearGradient(
                            colors: [
                                Color(hex: "080B12"),
                                Color(hex: "121624"),
                                Color(hex: "1C2235")
                            ],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                        .blur(radius: 20)
                        
                        MinimalistPatternView()
                            .opacity(0.3)
                    }
                    
                    // Buttons and Title
                    header
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                .frame(height: 175)
                .clipShape(RoundedCorner(radius: 36, corners: [.bottomLeft, .bottomRight]))
                .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 8)
            }
            .ignoresSafeArea(edges: .top)
            .zIndex(1)
        }
        .navigationBarHidden(true)
        .task {
            // TEMP: Seed fake notifications for visual preview
            guard let uid = authService.currentUser?.id,
                  notificationService.notifications.isEmpty else { return }
            
            let samples: [(NotificationType, String, String)] = [
                (.debt, "Parcela próxima do vencimento", "Sua parcela do iPhone 15 Pro vence em 3 dias. Valor: R$ 499,90"),
                (.spending, "Resumo semanal de gastos", "Você gastou R$ 1.247,00 esta semana. Alimentação foi a maior categoria."),
                (.insight, "Insight da IA", "Seus gastos com transporte aumentaram 42% comparado ao mês passado."),
                (.crm, "Novidade Concierge", "Nova funcionalidade disponível! Agora você pode exportar seus dados em PDF."),
                (.system, "Backup realizado", "Seus dados foram sincronizados com sucesso às 03:00.")
            ]
            
            for (i, sample) in samples.enumerated() {
                await notificationService.createNotification(
                    userId: uid,
                    type: sample.0,
                    title: sample.1,
                    body: sample.2
                )
                // Small delay so createdAt differs
                if i < samples.count - 1 {
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
            
            Spacer()
            
            Text("Notificações")
                .font(.custom("Georgia", size: 22))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.4), radius: 8, x: 0, y: 0)
            
            Spacer()
            
            // Mark all as read
            Button(action: {
                guard let uid = authService.currentUser?.id else { return }
                Task { await notificationService.markAllAsRead(userId: uid) }
            }) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(notificationService.unreadCount > 0 ? Theme.gold : .white.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
            .disabled(notificationService.unreadCount == 0)
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bell.slash")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Theme.textTertiary)
            }
            
            VStack(spacing: 8) {
                Text("Nenhuma notificação")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Quando houver novidades, elas aparecerão aqui.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textTertiary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Notifications List
    private var notificationsList: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 8)
                    
                    ForEach(groupedNotifications, id: \.0) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            // Section Header
                            Text(group.0.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(Theme.gold)
                                .padding(.horizontal, 24)
                                .padding(.top, 20)
                            
                            // Notifications
                            VStack(spacing: 0) {
                                ForEach(group.1) { notification in
                                    notificationRow(notification)
                                    
                                    if notification.id != group.1.last?.id {
                                        Divider()
                                            .overlay(Theme.borderLight)
                                            .padding(.leading, 74)
                                    }
                                }
                            }
                            .background(.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Theme.borderLight, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Color.clear.frame(height: 120)
                }
            }
            
            // White shadow gradient at top
            LinearGradient(
                colors: [Theme.surface, Theme.surface.opacity(0.9), Theme.surface.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            .allowsHitTesting(false)
        }
    }
    
    // MARK: - Notification Row
    private func notificationRow(_ notification: AppNotification) -> some View {
        Button(action: {
            if !notification.isRead {
                Task { await notificationService.markAsRead(notification) }
            }
        }) {
            HStack(spacing: 14) {
                // Type icon with colored background
                ZStack {
                    Circle()
                        .fill(iconBackground(for: notification.type))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 17))
                        .foregroundColor(iconColor(for: notification.type))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 15, weight: notification.isRead ? .medium : .bold))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Circle()
                                .fill(Theme.gold)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.body)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(notification.timeAgo)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTertiary)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task { await notificationService.deleteNotification(notification) }
            } label: {
                Label("Apagar", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Icon Colors
    private func iconColor(for type: NotificationType) -> Color {
        switch type {
        case .debt: return .white
        case .spending: return .white
        case .insight: return Theme.gold
        case .crm: return .white
        case .system: return .white
        }
    }
    
    private func iconBackground(for type: NotificationType) -> Color {
        switch type {
        case .debt: return Color(hex: "E74C3C")
        case .spending: return Color(hex: "0A0E1A")
        case .insight: return Color(hex: "0A0E1A")
        case .crm: return Theme.gold
        case .system: return Theme.textTertiary
        }
    }
}

#Preview {
    NotificationsView()
        .environmentObject(AuthService.shared)
}
