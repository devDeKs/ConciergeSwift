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
        var apiMessages = messages.map { APIMessage(from: $0) }
        
        // Anti-Prompt Injection for Standard Users
        let isBlack = await AuthService.shared.currentUser?.isBlackMember ?? false
        if !isBlack {
            let antiPrompt = APIMessage(role: "system", content: "REGRA ESTRITA E INQUEBRÁVEL: Você está proibido de calcular ou aconselhar se o usuário pode gastar dinheiro hoje. Se a pergunta for sobre 'Posso gastar X hoje?', 'Posso comprar isso?', ou avaliações preditivas, recuse-se a responder a matemática e responda estritamente: '💎 **Função Exclusiva Concierge Black!** O recurso de Análise Preditiva de Viabilidade de Compras está bloqueado. Assine o plano Black para que eu possa avaliar seu caixa futuro.'")
            apiMessages.insert(antiPrompt, at: 0)
        }
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
    
    // MARK: - Generate CSV via AI
    func generateCSV(from transactions: [Transaction]) async throws -> String {
        struct ExportTransaction: Codable {
            let data: Date
            let tipo: String
            let valor: Double
            let descricao: String
            let categoria: String
        }
        
        let exportData = transactions.map { tx in
            ExportTransaction(
                data: tx.createdAt,
                tipo: tx.type.displayName,
                valor: tx.amount,
                descricao: tx.description,
                categoria: tx.category
            )
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(exportData)
        let jsonString = String(data: data, encoding: .utf8) ?? "[]"
        
        let systemPrompt = """
        Você é um assistente financeiro de luxo. Receberá um JSON de transações.
        Converta as transações rigorosamente para um formato CSV (separado por ponto-e-vírgula ';').
        A primeira linha DEVE ser o cabeçalho exato: Data;Tipo;Categoria;Descrição;Valor.
        Ordene da mais antiga para a mais recente.
        A Data deve ser traduzida para o formato local (DD/MM/AAAA).
        O Valor deve ser formatado com duas casas decimais e vírgula (ex: 1500,50).
        Retorne APENAS o texto crú do CSV. NÃO INCLUA NENHUMA LETRA/PALAVRA FORA DO CSV E NÃO USE MARKDOWN (```).
        """
        
        let promptMessage = Message(role: .user, content: "\(systemPrompt)\n\nJSON:\n\(jsonString)")
        
        let result = try await sendMessage([promptMessage])
        
        // Remove markdown artifacts se a IA ignorar o comando
        var cleanResult = result.replacingOccurrences(of: "```csv\n", with: "")
        cleanResult = cleanResult.replacingOccurrences(of: "```\n", with: "")
        cleanResult = cleanResult.replacingOccurrences(of: "```", with: "")
        return cleanResult.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    // MARK: - Extract Transaction JSON from AI Response
    func extractJSONTransaction(from text: String) -> (cleanText: String, parsed: (type: TransactionType, amount: Double, description: String, category: String)?, needsCategory: Bool) {
        
        var cleanText = text
        var needsCategory = false
        
        // Verifica se a IA pediu categoria explícita através de botões interativos
        if cleanText.contains("[[ASK_CATEGORY]]") {
            needsCategory = true
            cleanText = cleanText.replacingOccurrences(of: "[[ASK_CATEGORY]]", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // O padrão busca: [[TRANSACTION: {"type":...}]]
        let pattern = "\\[\\[TRANSACTION:\\s*(\\{.*?\\})\\s*\\]\\]"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) else {
            return (cleanText, nil, needsCategory)
        }
        
        let jsonRange = match.range(at: 1)
        let fullMatchRange = match.range(at: 0)
        
        guard let jsonStringRange = Range(jsonRange, in: cleanText),
              let fullStringRange = Range(fullMatchRange, in: cleanText) else {
            return (cleanText, nil, needsCategory)
        }
        
        let jsonString = String(cleanText[jsonStringRange])
        
        // Remove a tag oculta da mensagem que vai para o usuário
        cleanText.removeSubrange(fullStringRange)
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse do JSON
        guard let jsonData = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let typeStr = dict["type"] as? String,
              let type = TransactionType(rawValue: typeStr),
              let amountNumber = dict["amount"] as? NSNumber,
              let description = dict["description"] as? String else {
            return (cleanText, nil, needsCategory)
        }
        
        let amount = amountNumber.doubleValue
        
        let category = dict["category"] as? String ?? "Outros"
        
        return (cleanText, (type: type, amount: amount, description: description, category: category), needsCategory)
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
