//
//  AuthView.swift
//  ConciergeSwift
//
//  Premium Dark Auth Flow - 3 Screens (Welcome → Login / Register)
//

import SwiftUI

// MARK: - Auth Flow Pages
enum AuthPage {
    case welcome
    case login
    case register
}

struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @State private var currentPage: AuthPage = .welcome
    
    // Form State
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            Theme.midnight
                .ignoresSafeArea()
            
            switch currentPage {
            case .welcome:
                welcomeView
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .login:
                loginView
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .register:
                registerView
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: currentPage)
        .alert("Erro", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = frame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }
    
    // MARK: - Screen 1: Welcome
    private var welcomeView: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Hero Image - 60% of screen with shadow
                ZStack(alignment: .center) {
                    // Load from Bundle (bypasses Asset Catalog issues)
                    if let path = Bundle.main.path(forResource: "welcome_hero", ofType: "png"),
                       let uiImage = UIImage(contentsOfFile: path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height * 0.65)
                            .clipped()
                    } else {
                        // Fallback: Programmatic gradient if image not found
                        WaveGradientView()
                            .frame(width: geo.size.width, height: geo.size.height * 0.65)
                    }
                    
                    // Gradient fade into midnight (soft, starts late)
                    VStack {
                        Spacer()
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: Theme.midnight.opacity(0.02), location: 0.2),
                                .init(color: Theme.midnight.opacity(0.08), location: 0.35),
                                .init(color: Theme.midnight.opacity(0.18), location: 0.5),
                                .init(color: Theme.midnight.opacity(0.35), location: 0.65),
                                .init(color: Theme.midnight.opacity(0.55), location: 0.75),
                                .init(color: Theme.midnight.opacity(0.75), location: 0.85),
                                .init(color: Theme.midnight.opacity(0.9), location: 0.93),
                                .init(color: Theme.midnight, location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 200)
                    }
                    
                    // Logo overlaid
                    VStack(spacing: 12) {
                        Text("Concierge")
                            .font(.custom("Georgia", size: 38))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.7), radius: 20, y: 6)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.gold)
                            .frame(width: 40, height: 3)
                    }
                }
                .frame(height: geo.size.height * 0.65)
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                
                // Content below - 40%
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Text("Seu Copiloto Financeiro")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("O gestor definitivo para quem busca\npraticidade e controle.")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation { currentPage = .register }
                    } label: {
                        Text("INICIAR AGORA")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Theme.midnight)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Theme.gold)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    Button {
                        withAnimation { currentPage = .login }
                    } label: {
                        Text("Acessar conta existente")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .padding(.top, 20)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Screen 2: Login
    private var loginView: some View {
        ZStack(alignment: .top) {
            // Background: Hero image
            heroBackground
            
            // Bottom Card
            VStack(spacing: 0) {
                Spacer()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ACESSO")
                                .font(.system(size: 13, weight: .bold))
                                .tracking(3)
                                .foregroundColor(Theme.gold)
                            
                            Text("Bem-vindo de volta")
                                .font(.custom("Georgia", size: 30))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                        
                        // Email
                        DarkFieldView(
                            label: "ENDEREÇO DE EMAIL",
                            placeholder: "exemplo@concierge.com",
                            text: $email,
                            icon: "envelope.fill",
                            isSecure: false
                        )
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("SUA SENHA")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(2)
                                    .foregroundColor(Theme.gold.opacity(0.7))
                                
                                Spacer()
                                
                                Button {
                                    // Recover password action
                                } label: {
                                    Text("RECUPERAR")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(Theme.gold.opacity(0.7))
                                }
                            }
                            
                            DarkInputBox(
                                placeholder: "••••••••",
                                text: $password,
                                icon: "lock.fill",
                                isSecure: true
                            )
                        }
                        .padding(.top, 24)
                        
                        Spacer().frame(height: 48)
                        
                        // Action Button
                        Button(action: handleLogin) {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(Theme.midnight)
                                } else {
                                    Text("ENTRAR NO SISTEMA")
                                        .font(.system(size: 14, weight: .bold))
                                        .tracking(1.5)
                                }
                            }
                            .foregroundColor(Theme.midnight)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Theme.gold)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading || !isLoginValid)
                        .opacity(isLoginValid ? 1 : 0.5)
                        
                        // Toggle Link
                        HStack(spacing: 4) {
                            Text("Ainda não é membro?")
                                .foregroundColor(.white.opacity(0.45))
                            Button {
                                withAnimation { currentPage = .register }
                                clearForm()
                            } label: {
                                Text("Solicitar Acesso")
                                    .foregroundColor(Theme.gold)
                                    .underline()
                            }
                        }
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 28)
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.65)
                .background(
                    ZStack(alignment: .top) {
                        Theme.midnight
                            .padding(.top, 100)
                        
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: Theme.midnight.opacity(0.02), location: 0.2),
                                .init(color: Theme.midnight.opacity(0.08), location: 0.35),
                                .init(color: Theme.midnight.opacity(0.18), location: 0.5),
                                .init(color: Theme.midnight.opacity(0.35), location: 0.65),
                                .init(color: Theme.midnight.opacity(0.55), location: 0.75),
                                .init(color: Theme.midnight.opacity(0.75), location: 0.85),
                                .init(color: Theme.midnight.opacity(0.9), location: 0.93),
                                .init(color: Theme.midnight, location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 350)
                        .offset(y: -250)
                    }
                    .ignoresSafeArea(edges: .bottom)
                )
                .offset(y: -keyboardHeight * 0.5)
            }
            
            // Back Button (floating over image)
            HStack {
                Button {
                    withAnimation { currentPage = .welcome }
                    clearForm()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 56)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Screen 3: Register
    private var registerView: some View {
        ZStack(alignment: .top) {
            // Background: Hero image
            heroBackground
            
            // Bottom Card
            VStack(spacing: 0) {
                Spacer()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("REGISTRO")
                                .font(.system(size: 13, weight: .bold))
                                .tracking(3)
                                .foregroundColor(Theme.gold)
                            
                            Text("Criar nova conta")
                                .font(.custom("Georgia", size: 30))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                        
                        // Name
                        DarkFieldView(
                            label: "NOME COMPLETO",
                            placeholder: "Seu nome",
                            text: $name,
                            icon: "person.fill",
                            isSecure: false
                        )
                        
                        // Email
                        DarkFieldView(
                            label: "ENDEREÇO DE EMAIL",
                            placeholder: "exemplo@concierge.com",
                            text: $email,
                            icon: "envelope.fill",
                            isSecure: false
                        )
                        .padding(.top, 24)
                        
                        // Password
                        DarkFieldView(
                            label: "SENHA DE ACESSO",
                            placeholder: "••••••••",
                            text: $password,
                            icon: "lock.fill",
                            isSecure: true
                        )
                        .padding(.top, 24)
                        
                        Spacer().frame(height: 48)
                        
                        // Action Button
                        Button(action: handleRegister) {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(Theme.midnight)
                                } else {
                                    Text("FINALIZAR CADASTRO")
                                        .font(.system(size: 14, weight: .bold))
                                        .tracking(1.5)
                                }
                            }
                            .foregroundColor(Theme.midnight)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Theme.gold)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading || !isRegisterValid)
                        .opacity(isRegisterValid ? 1 : 0.5)
                        
                        // Toggle Link
                        HStack(spacing: 4) {
                            Text("Já possui acesso?")
                                .foregroundColor(.white.opacity(0.45))
                            Button {
                                withAnimation { currentPage = .login }
                                clearForm()
                            } label: {
                                Text("Fazer Login")
                                    .foregroundColor(Theme.gold)
                                    .underline()
                            }
                        }
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 28)
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.65)
                .background(
                    ZStack(alignment: .top) {
                        Theme.midnight
                            .padding(.top, 100)
                        
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: Theme.midnight.opacity(0.02), location: 0.2),
                                .init(color: Theme.midnight.opacity(0.08), location: 0.35),
                                .init(color: Theme.midnight.opacity(0.18), location: 0.5),
                                .init(color: Theme.midnight.opacity(0.35), location: 0.65),
                                .init(color: Theme.midnight.opacity(0.55), location: 0.75),
                                .init(color: Theme.midnight.opacity(0.75), location: 0.85),
                                .init(color: Theme.midnight.opacity(0.9), location: 0.93),
                                .init(color: Theme.midnight, location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 350)
                        .offset(y: -250)
                    }
                    .ignoresSafeArea(edges: .bottom)
                )
                .offset(y: -keyboardHeight * 0.5)
            }
            
            // Back Button (floating over image)
            HStack {
                Button {
                    withAnimation { currentPage = .welcome }
                    clearForm()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 56)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Shared Hero Background
    private var heroBackground: some View {
        GeometryReader { geo in
            if let path = Bundle.main.path(forResource: "welcome_hero", ofType: "png"),
               let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                WaveGradientView()
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Validation
    private var isLoginValid: Bool {
        email.contains("@") && email.contains(".") && password.count >= 6
    }
    
    private var isRegisterValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") && email.contains(".") &&
        password.count >= 6
    }
    
    // MARK: - Actions
    private func handleLogin() {
        isLoading = true
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
    
    private func handleRegister() {
        isLoading = true
        Task {
            do {
                try await authService.signUp(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
    
    private func clearForm() {
        name = ""
        email = ""
        password = ""
    }
}

// MARK: - Reusable Dark Field (Label + InputBox)
struct DarkFieldView: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(Theme.gold.opacity(0.7))
            
            DarkInputBox(
                placeholder: placeholder,
                text: $text,
                icon: icon,
                isSecure: isSecure
            )
        }
    }
}

// MARK: - Dark Input Box (Icon + Field)
struct DarkInputBox: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 20)
            
            if isSecure {
                SecureField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(.white.opacity(0.25))
                    }
                    .foregroundColor(.white)
                    .autocapitalization(.none)
            } else {
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(.white.opacity(0.25))
                    }
                    .foregroundColor(.white)
                    .keyboardType(icon == "envelope.fill" ? .emailAddress : .default)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Programmatic Wave Gradient (Blue + White Silk)
struct WaveGradientView: View {
    var body: some View {
        Canvas { context, size in
            // Base: Deep navy
            let bgRect = CGRect(origin: .zero, size: size)
            context.fill(Path(bgRect), with: .color(Color(red: 0.06, green: 0.08, blue: 0.18)))
            
            // Draw multiple flowing wave bands
            let waveConfigs: [(yOffset: CGFloat, thickness: CGFloat, opacity: Double, color: Color)] = [
                (0.15, 0.28, 0.35, .white),
                (0.30, 0.22, 0.20, Color(red: 0.4, green: 0.55, blue: 0.85)),
                (0.50, 0.30, 0.30, .white),
                (0.65, 0.18, 0.15, Color(red: 0.3, green: 0.45, blue: 0.75)),
                (0.80, 0.25, 0.25, .white),
            ]
            
            for config in waveConfigs {
                var path = Path()
                let baseY = size.height * config.yOffset
                let amplitude: CGFloat = size.height * 0.08
                
                path.move(to: CGPoint(x: -20, y: baseY))
                
                for x in stride(from: -20, through: size.width + 20, by: 2) {
                    let normalizedX = x / size.width
                    let y = baseY
                        + sin(normalizedX * .pi * 2.5 + config.yOffset * 8) * amplitude
                        + cos(normalizedX * .pi * 1.2 + config.yOffset * 4) * (amplitude * 0.5)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                // Close the band shape
                let bandBottom = baseY + size.height * config.thickness
                path.addLine(to: CGPoint(x: size.width + 20, y: bandBottom))
                
                for x in stride(from: size.width + 20, through: -20, by: -2) {
                    let normalizedX = x / size.width
                    let y = bandBottom
                        + sin(normalizedX * .pi * 2.0 + config.yOffset * 6) * (amplitude * 0.6)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.closeSubpath()
                
                context.fill(path, with: .color(config.color.opacity(config.opacity)))
            }
            
            // Subtle highlight streaks
            for i in 0..<3 {
                var streak = Path()
                let startY = size.height * (0.2 + Double(i) * 0.25)
                streak.move(to: CGPoint(x: 0, y: startY))
                streak.addQuadCurve(
                    to: CGPoint(x: size.width, y: startY + size.height * 0.1),
                    control: CGPoint(x: size.width * 0.5, y: startY - 30)
                )
                context.stroke(
                    streak,
                    with: .color(.white.opacity(0.12)),
                    lineWidth: 1.5
                )
            }
        }
    }
}

// MARK: - Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthService.shared)
}
