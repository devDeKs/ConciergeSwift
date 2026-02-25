//
//  AIService.swift
//  ConciergeSwift
//
//  AI chat service using Cloudflare Workers endpoint
//

import Foundation

class AIService {
    static let shared = AIService()
    
    // Cloudflare Worker endpoint (same as React Native app)
    private let apiURL = "https://concierge-ai-chat.deksboyz07.workers.dev"
    
    private init() {}
    
    // MARK: - Send Message
    func sendMessage(_ messages: [Message]) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // Convert messages to API format
        let apiMessages = messages.map { APIMessage(from: $0) }
        let body = ["messages": apiMessages]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIError.serverError(httpResponse.statusCode)
        }
        
        // Parse OpenRouter response format: choices[0].message.content
        if let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = responseDict["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        // Fallback: try raw string
        if let responseString = String(data: data, encoding: .utf8) {
            return responseString
        }
        
        throw AIError.parsingError
    }
    // MARK: - Extract Transaction JSON from AI Response
    func extractJSONTransaction(from text: String) -> (cleanText: String, parsed: (type: TransactionType, amount: Double, description: String, category: String)?) {
        // O padrão busca: [[TRANSACTION: {"type":...}]]
        let pattern = "\\[\\[TRANSACTION:\\s*(\\{.*?\\})\\s*\\]\\]"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) else {
            return (text, nil)
        }
        
        let jsonRange = match.range(at: 1)
        let fullMatchRange = match.range(at: 0)
        
        guard let jsonStringRange = Range(jsonRange, in: text),
              let fullStringRange = Range(fullMatchRange, in: text) else {
            return (text, nil)
        }
        
        let jsonString = String(text[jsonStringRange])
        
        // Remove a tag oculta da mensagem que vai para o usuário
        var cleanText = text
        cleanText.removeSubrange(fullStringRange)
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse do JSON
        guard let jsonData = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let typeStr = dict["type"] as? String,
              let type = TransactionType(rawValue: typeStr),
              let amountNumber = dict["amount"] as? NSNumber,
              let description = dict["description"] as? String else {
            return (cleanText, nil)
        }
        
        let amount = amountNumber.doubleValue
        
        let category = dict["category"] as? String ?? "Outros"
        
        return (cleanText, (type: type, amount: amount, description: description, category: category))
    }
}

// MARK: - AI Errors
enum AIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case parsingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidResponse:
            return "Resposta inválida do servidor"
        case .serverError(let code):
            return "Erro do servidor: \(code)"
        case .parsingError:
            return "Erro ao processar resposta"
        case .networkError:
            return "Erro de conexão"
        }
    }
}
