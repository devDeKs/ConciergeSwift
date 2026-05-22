//
//  ChatView.swift
//  ConciergeSwift
//
//  AI Chat interface - Refined Design (Frontend Specialist)
//  Light theme, fluid animations, polished input area, Quick Templates
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    @State private var showBlackPopup = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Soft off-white background
            Color(hex: "F8F9FA")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Spacer for fixed header (matches header height minus bottom safe area overlap if needed)
                Color.clear
                    .frame(height: 95)
                
                // Messages Area
                messagesView
                    .onTapGesture {
                        isInputFocused = false
                    }
                
                // Input Area
                inputArea
            }
            
            // Fixed Header
            chatHeader
                .ignoresSafeArea(edges: .top)
            
            // Popups & Paywalls
            if showBlackPopup {
                BlackFeaturePopup(isPresented: $showBlackPopup) {
                    viewModel.showPaywall = true
                }
                .zIndex(100)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showPaywall) {
            ConciergeBlackView()
        }
        .onAppear {
            if let message = appState.pendingChatMessage {
                viewModel.inputText = message
                appState.pendingChatMessage = nil // Clear it so it doesn't fire again
                
                if appState.shouldFocusChatInput {
                    appState.shouldFocusChatInput = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isInputFocused = true
                    }
                } else {
                    // Slight delay to allow view to render before sending
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        sendMessage()
                    }
                }
            } else if appState.shouldFocusChatInput {
                appState.shouldFocusChatInput = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInputFocused = true
                }
            }
        }
    }
    
    // MARK: - Chat Header
    private var chatHeader: some View {
        HStack {
            Text("Concierge")
                .font(.custom("Georgia", size: 26))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.4), radius: 8, x: 0, y: 0)
            
            Spacer()
            
            Text("IA")
                .font(.system(size: 14, weight: .bold)) // Aumentei o texto
                .tracking(1)
                .foregroundColor(Theme.gold)
                .padding(.horizontal, 16) // Aumentei o background lateral
                .padding(.vertical, 8)    // Aumentei o background vertical
                .background(Theme.gold.opacity(0.15))
                .cornerRadius(14)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28) // Adjust alignment
        .frame(height: 150, alignment: .bottom) // Adjusted fixed height including safe area
        .background(
            ZStack {
                // Dark Gradient Background
                LinearGradient(
                    colors: [
                        Color(hex: "080B12"),
                        Color(hex: "121624"),
                        Color(hex: "1C2235")
                    ],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
                
                // Geometric Pattern
                MinimalistPatternView()
                    .opacity(0.6)
            }
            .clipShape(RoundedCorner(radius: 32, corners: [.bottomLeft, .bottomRight]))
            .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)
        )
    }
    
    // MARK: - Messages View
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Intro Bubble (Fixed or just first message)
                    if viewModel.messages.isEmpty {
                        // Welcome Message
                        BotMessageBubble(content: "Olá! Sou seu Concierge Financeiro. Como posso ajudar hoje?")
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        ForEach(viewModel.messages) { message in
                            if message.role == .user {
                                UserMessageBubble(content: message.content)
                                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                                    .id(message.id)
                            } else {
                                VStack(alignment: .leading, spacing: 12) {
                                    BotMessageBubble(content: message.content)
                                        .transition(.opacity.combined(with: .move(edge: .leading)))
                                        .id(message.id)
                                    
                                    if message.needsCategory {
                                        CategorySelectionView(action: { category in
                                            viewModel.inputText = "A categoria é \(category)"
                                            viewModel.simulateSend() // we need a way to send it immediately
                                        })
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                    }
                                }
                            }
                        }
                    }
                    
                    if viewModel.isTyping {
                        TypingBubble()
                            .id("typing")
                            .transition(.opacity)
                    }
                    
                    // Spacer for bottom input
                    Color.clear.frame(height: 20)
                        .id("bottom_spacer")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // Scroll to the latest message or the bottom spacer to ensure full visibility
                withAnimation(.spring()) {
                    if let lastId = viewModel.messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    } else {
                        proxy.scrollTo("bottom_spacer", anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isTyping) { _, isTyping in
                if isTyping {
                    withAnimation(.spring()) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        VStack(spacing: 12) {
            // Quick Templates
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Spacer().frame(width: 20)
                    
                    GoldShimmerButton(icon: "bag", label: "Posso Gastar Hoje ?") {
                        if let user = authService.currentUser, user.isBlackMember {
                            viewModel.inputText = "Posso gastar R$ (Insira o valor) hoje ?"
                            isInputFocused = true
                        } else {
                            showBlackPopup = true
                        }
                    }
                    
                    QuickTemplateButton(icon: "creditcard", label: "Registrar Gasto") {
                        viewModel.inputText = "Gastei R$ "
                        isInputFocused = true
                    }
                    
                    QuickTemplateButton(icon: "banknote", label: "Registrar Receita") {
                        viewModel.inputText = "Recebi R$ "
                        isInputFocused = true
                    }
                    
                    QuickTemplateButton(icon: "chart.pie", label: "Ver Resumo") {
                        viewModel.inputText = "Como estão meus gastos este mês?"
                        sendMessage()
                    }
                    
                    Spacer().frame(width: 20)
                }
            }
            .padding(.top, 8)
            // Removed clipShape that was creating an artificial cut-off block
            
            HStack(spacing: 16) {
                // Microphone / Input Container
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "mic")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.midnight.opacity(0.4))
                    }
                    
                    TextField("", text: $viewModel.inputText, prompt: Text("Diga algo...").foregroundColor(Theme.midnight.opacity(0.5)))
                        .font(.system(size: 16))
                        .foregroundColor(Theme.midnight)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            sendMessage()
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                
                // Send Button (Gold with Shadow)
                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(Theme.gold)
                            .frame(width: 56, height: 56)
                            .shadow(color: Theme.gold.opacity(0.4), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20)) // Slightly tilted or standard
                            .foregroundColor(.white)
                            .offset(x: -2, y: 2) // Optical adjustment
                    }
                }
                .disabled(!viewModel.canSend)
                .opacity(viewModel.canSend ? 1.0 : 0.8)
                .scaleEffect(viewModel.canSend ? 1.0 : 0.95)
                .animation(.spring(), value: viewModel.canSend)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, isInputFocused ? 16 : 80) // Reduced padding when keyboard is open to avoid pushing input too high
            .padding(.top, 4)
            .zIndex(10) // Ensure the input area + templates shadow casts OVER the messages behind it
        }
        .background(
            LinearGradient(
                colors: [Theme.background.opacity(0), Theme.background, Theme.background], // More solid at bottom
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Actions
    private func sendMessage() {
        guard viewModel.canSend else { return }
        Task {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            await viewModel.sendMessage()
        }
    }
}

// MARK: - Category Selection View
struct CategorySelectionView: View {
    let action: (String) -> Void
    
    let categories = [
        ("Alimentação", "E8C382", "fork.knife"),
        ("Transporte", "1DD1A1", "car.fill"),
        ("Casa", "8A2BE2", "house.fill"),
        ("Saúde", "FF6B6B", "cross.case.fill"),
        ("Educação", "48DBFB", "book.fill"),
        ("Lazer", "FF9F43", "play.tv.fill"),
        ("Outros", "95A5A6", "cart.fill")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Spacer().frame(width: 8)
                
                ForEach(categories, id: \.0) { cat in
                    Button(action: { action(cat.0) }) {
                        HStack(spacing: 6) {
                            Image(systemName: cat.2)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: cat.1))
                            
                            Text(cat.0)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.midnight)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(hex: cat.1).opacity(0.3), lineWidth: 1))
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                }
                
                Spacer().frame(width: 20)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Bot Message Bubble
struct BotMessageBubble: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.gold)
                Spacer()
            }
            
            Text(LocalizedStringKey(content))
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Theme.midnight.opacity(0.9))
                .lineSpacing(4)
                .tint(Theme.gold) // For any links if present
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Theme.midnight.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        )
        // Bubble rounded corners logic: Standard is all rounded for bot in this reference
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 40) // Don't stretch full width
    }
}

// MARK: - User Message Bubble
struct UserMessageBubble: View {
    let content: String
    
    var body: some View {
        Text(LocalizedStringKey(content))
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Theme.midnight)
            .clipShape(RoundedCorner(radius: 24, corners: [.topLeft, .topRight, .bottomLeft]))
            .shadow(color: Theme.midnight.opacity(0.2), radius: 8, x: 0, y: 4)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.leading, 60)
    }
}

// MARK: - Typing Bubble
struct TypingBubble: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Theme.gold)
                    .frame(width: 8, height: 8)
                    .offset(y: offset)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: offset
                    )
            }
        }
        .onAppear { offset = -5 }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Quick Template Button
struct QuickTemplateButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.gold)
                
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.midnight.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white)
            )
            .overlay(
                Capsule()
                    .stroke(Theme.midnight.opacity(0.05), lineWidth: 1)
            )
        }
    }
}

// MARK: - Gold Shimmer Button
struct GoldShimmerButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.midnight)
                
                Text(label)
                    .font(.system(size: 13, weight: .medium)) // Reverted to normal/medium weight
                    .foregroundColor(Theme.midnight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Theme.gold, Theme.gold.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .overlay(
                // 3 Animated Sparkles in Top Right
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.system(size: 14)) // Slightly larger
                            .foregroundColor(.white)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .opacity(isAnimating ? 1.0 : 0.5) // Higher base opacity
                            .offset(x: -2, y: -2) // Pushed slightly outside the physical top right bound for depth
                    }
                    Spacer()
                }
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Chat ViewModel (Reused logic, simplified state)
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var isTyping = false
    @Published var showPaywall = false
    
    var userId: String? {
        AuthService.shared.currentUser?.id
    }
    
    private let aiService = AIService.shared
    private let firestoreService = FirestoreService.shared
    
    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isTyping
    }
    
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        
        if let user = AuthService.shared.currentUser, !user.isBlackMember {
            let calendar = Calendar.current
            var count = user.dailyAIMessageCount
            let lastDate = user.lastAIMessageDate ?? Date.distantPast
            
            if calendar.isDateInToday(lastDate) {
                if count >= 5 {
                    showPaywall = true
                    return
                }
                count += 1
            } else {
                count = 1
            }
            
            do {
                try await firestoreService.updateUserProfile(userId: user.id, data: [
                    "dailyAIMessageCount": count,
                    "lastAIMessageDate": Date()
                ])
                await AuthService.shared.refreshUser()
            } catch { print("Failed to update limit") }
        }
        
        inputText = ""
        
        // Add user message
        let userMessage = Message(role: .user, content: text)
        withAnimation {
            messages.append(userMessage)
        }
        
        isTyping = true
        
        // Simulate delay or real AI call
        // Real implementation
        do {
            // Prepara a cópia de mensagens para o Bot com o "Ponto Eletrônico"
            var messagesForAI = messages
            
            if let userId = userId, let lastIndex = messagesForAI.lastIndex(where: { $0.role == .user }) {
                let contextStr = await firestoreService.getMonthlyContextString(userId: userId)
                let debtsStr = await firestoreService.getDebtsContextString(userId: userId)
                let enhancedContent = "\(messagesForAI[lastIndex].content)\n\n\(contextStr)\n\(debtsStr)"
                messagesForAI[lastIndex] = Message(id: messagesForAI[lastIndex].id, role: .user, content: enhancedContent, timestamp: messagesForAI[lastIndex].timestamp)
            }
            
            // Envia o array com o contexto invisível para o Worker (que já injeta a Persona)
            let response = try await aiService.sendMessage(messagesForAI)
            
            // Tenta extrair a tag secreta de transação gerada pela nova IA
            let extracted = aiService.extractJSONTransaction(from: response)
            let cleanResponse = extracted.cleanText
            
            // Se a IA gerou uma transação (extrato JSON válido), salva no Firestore
            if let parsed = extracted.parsed, let userId = userId {
                await saveTransactionByAI(parsed: parsed, userId: userId)
            }
            
            isTyping = false
            withAnimation {
                messages.append(Message(role: .assistant, content: cleanResponse, needsCategory: extracted.needsCategory))
            }
        } catch {
            isTyping = false
            let errorMsg = (error as? AIError)?.errorDescription ?? error.localizedDescription
            messages.append(Message(role: .assistant, content: "⚠️ \(errorMsg)"))
        }
    }
    
    private func saveTransactionByAI(parsed: (type: TransactionType, amount: Double, description: String, category: String), userId: String) async {
        do {
            let transaction = Transaction(
                userId: userId,
                type: parsed.type,
                amount: parsed.amount,
                description: parsed.description,
                category: parsed.category,
                createdAt: Date()
            )
            try await firestoreService.addTransaction(transaction)
            print("✅ AI Transaction saved to Firestore: \(parsed.description)")
        } catch {
            print("❌ AI Transaction save error: \(error)")
        }
    }
    
    // Helper to send instantly from category button
    func simulateSend() {
        guard canSend else { return }
        Task {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            // Disable the previous needsCategory to collapse the buttons visually based on the last message
            if let lastAssistIndex = messages.lastIndex(where: { $0.role == .assistant }) {
                messages[lastAssistIndex].needsCategory = false
            }
            
            await sendMessage()
        }
    }
}

#Preview {
    ChatView()
}
