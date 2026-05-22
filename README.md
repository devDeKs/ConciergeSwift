# 💰 Concierge

> Your personal AI-powered financial concierge — a premium native iOS app built with SwiftUI.

Concierge is a personal finance management app that combines elegant design with AI intelligence. Track your transactions, manage cards, get financial insights, and chat with an AI assistant — all within a beautifully crafted dark-themed interface.

## ✨ Features

- **💳 Dashboard** — Real-time balance overview with premium gold-themed UI
- **📊 Transactions** — Full transaction history with search, filters by date range, and category breakdown
- **🃏 Cards** — Credit card management with installment tracking
- **🤖 AI Chat** — Conversational AI assistant for financial insights and monthly summaries
- **👤 Profile** — User profile management, currency selection, data export
- **🔔 Notifications** — Smart financial alerts and reminders
- **🔐 Authentication** — Secure Firebase Auth with email/password
- **💎 Concierge Black** — Premium subscription tier with StoreKit integration

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Platform** | iOS 17+ |
| **Language** | Swift 5.9 |
| **UI Framework** | SwiftUI |
| **Auth & Database** | Firebase Auth + Cloud Firestore |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **AI Backend** | Cloudflare Workers → OpenRouter API |
| **Payments** | StoreKit 2 |
| **Security** | Keychain Services |

## 📁 Project Structure

```
ConciergeSwift/
├── App/
│   ├── AppDelegate.swift          # Firebase init, FCM setup
│   └── ConciergeSwiftApp.swift    # App entry point, auth routing
├── Components/
│   └── MainTabView.swift          # Tab navigation (Home, Cards, Chat, Transactions, Profile)
├── Core/
│   ├── Models/
│   │   ├── AppNotification.swift  # Notification model
│   │   ├── Debt.swift             # Debt tracking model
│   │   ├── Message.swift          # Chat message model
│   │   ├── Transaction.swift      # Financial transaction model
│   │   └── User.swift             # User profile model
│   ├── Services/
│   │   ├── AIService.swift        # OpenRouter AI integration
│   │   ├── AuthService.swift      # Firebase Auth wrapper
│   │   ├── FirestoreService.swift # Firestore CRUD operations
│   │   ├── KeychainService.swift  # Secure credential storage
│   │   ├── NotificationService.swift # Push notification handling
│   │   └── StoreKitManager.swift  # In-app purchases
│   └── Theme.swift                # Design system (colors, styles)
├── Features/
│   ├── Auth/
│   │   └── AuthView.swift         # Login / Sign up
│   ├── Cards/
│   │   └── CardsView.swift        # Card management + installments
│   ├── Chat/
│   │   └── ChatView.swift         # AI chat interface
│   ├── Home/
│   │   └── HomeView.swift         # Dashboard with balance card
│   ├── Notifications/
│   │   └── NotificationsView.swift # Alerts and reminders
│   ├── Profile/
│   │   ├── ConciergeBlackView.swift    # Premium paywall
│   │   ├── CurrencySelectionView.swift # Multi-currency support
│   │   ├── EditProfileView.swift       # Profile editor
│   │   ├── ExportDataPopup.swift       # Data export (CSV/PDF)
│   │   ├── ProfileView.swift           # Profile dashboard
│   │   └── ProfileViewModel.swift      # Profile business logic
│   └── Transactions/
│       └── TransactionsView.swift # Transaction list + filters
└── Resources/
    ├── GoogleService-Info.plist   # Firebase configuration
    └── Info.plist                 # App configuration

workers/
└── chat-api.js                   # Cloudflare Worker (AI proxy)
```

## 🚀 Getting Started

### Prerequisites

- **Xcode 15+** (with Swift 5.9)
- **iOS 17+** simulator or device
- **Firebase project** configured with Auth + Firestore
- **Cloudflare account** (for AI worker deployment)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/devDeKs/ConciergeSwift.git
   cd ConciergeSwift
   ```

2. **Open in Xcode**
   ```bash
   open ConciergeSwift/ConciergeSwift.xcodeproj
   ```

3. **Wait for Swift Package Manager** to resolve dependencies (Firebase SDK)

4. **Configure Firebase**
   - Place your own `GoogleService-Info.plist` in `ConciergeSwift/ConciergeSwift/Resources/`
   - Enable Email/Password auth in Firebase Console
   - Create a Firestore database

5. **Run** — Select your target device/simulator → **⌘R**

### AI Backend Setup

The Cloudflare Worker in `workers/chat-api.js` proxies requests to OpenRouter API.

```bash
# Set your API key as a secret
npx wrangler secret put OPENROUTER_API_KEY

# Deploy the worker
npx wrangler deploy
```

## 🎨 Design System

The app follows a premium dark + gold aesthetic:

| Token | Value | Usage |
|-------|-------|-------|
| `Theme.gold` | `#B4975A` | Accent, CTAs, active states |
| `Theme.midnight` | `#020410` | Headers, dark backgrounds |
| `Theme.background` | `#FFFFFF` | Content areas |
| `Theme.success` | `#34D399` | Positive amounts |
| `Theme.error` | `#FB7185` | Negative amounts, alerts |

## 📄 License

This project is proprietary. All rights reserved.
