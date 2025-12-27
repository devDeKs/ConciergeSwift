import { GoogleGenAI } from "@google/genai";

const apiKey = process.env.GEMINI_API_KEY;
const genAI = apiKey ? new GoogleGenAI({ apiKey }) : null;

export const runtime = "edge";

export async function POST(req: Request) {
    if (!genAI) {
        return new Response(JSON.stringify({ error: "Gemini API Key not configured" }), {
            status: 500,
            headers: { "Content-Type": "application/json" },
        });
    }

    try {
        const { message } = await req.json();

        const response = await genAI.models.generateContent({
            model: "gemini-2.0-flash",
            contents: message,
            config: {
                systemInstruction: `Você é um parser de transações financeiras. Analise a mensagem do usuário e extraia:
- type: "income" para receitas/ganhos ou "expense" para despesas/gastos
- amount: valor numérico (número positivo)
- description: descrição curta (1-3 palavras)
- category: uma das categorias: Alimentação, Transporte, Lazer, Contas, Saúde, Compras, Educação, Trabalho, Freelance, Investimentos, Vendas, Outros

Responda APENAS em JSON válido, sem markdown, sem explicação:
{"type":"expense","amount":50,"description":"Uber","category":"Transporte"}

Se não conseguir identificar uma transação financeira, responda:
{"error":"not_transaction"}

Exemplos:
- "gastei 50 no uber" → {"type":"expense","amount":50,"description":"Uber","category":"Transporte"}
- "recebi 5000 de salário" → {"type":"income","amount":5000,"description":"Salário","category":"Trabalho"}
- "paguei 150 de luz" → {"type":"expense","amount":150,"description":"Conta de luz","category":"Contas"}
- "olá como vai" → {"error":"not_transaction"}`
            }
        });

        const text = response.text?.trim() || "";

        // Try to parse as JSON
        try {
            const parsed = JSON.parse(text);
            return new Response(JSON.stringify(parsed), {
                status: 200,
                headers: { "Content-Type": "application/json" },
            });
        } catch {
            // If parsing fails, return error
            return new Response(JSON.stringify({ error: "parse_failed", raw: text }), {
                status: 200,
                headers: { "Content-Type": "application/json" },
            });
        }
    } catch (error) {
        console.error("Gemini Parse API Error:", error);
        return new Response(JSON.stringify({ error: "api_failed" }), {
            status: 500,
            headers: { "Content-Type": "application/json" },
        });
    }
}
