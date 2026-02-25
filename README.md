# Concierge

App financeiro pessoal nativo para iOS, construído em **Swift/SwiftUI**.

## Stack

- **iOS App**: Swift 5.9+ / SwiftUI / iOS 17+
- **Auth & Database**: Firebase Auth + Firestore
- **AI Backend**: Cloudflare Worker → OpenRouter API

## Estrutura

```
ConciergeSwift/          # App iOS nativo
├── App/                 # Entry point (AppDelegate, App)
├── Components/          # Componentes reutilizáveis
├── Core/                # Models, Services, Theme, Extensions
├── Features/            # Telas (Auth, Home, Cards, Chat, Profile)
└── Resources/           # Assets, GoogleService-Info.plist

workers/                 # Cloudflare Worker (proxy AI)
└── chat-api.js
```

## Como Rodar

1. Abrir `ConciergeSwift/ConciergeSwift.xcodeproj` no Xcode
2. Aguardar resolução dos Swift Packages (Firebase SDK)
3. Selecionar dispositivo/simulador → **Run (⌘R)**

## AI Backend

O worker Cloudflare em `workers/chat-api.js` faz proxy para a OpenRouter API. Deploy via:

```bash
npx wrangler deploy workers/chat-api.js
```
