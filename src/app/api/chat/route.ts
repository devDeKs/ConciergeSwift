import { GoogleGenerativeAI } from "@google/generative-ai";

const apiKey = process.env.GEMINI_API_KEY;
const genAI = apiKey ? new GoogleGenerativeAI(apiKey) : null;

export const runtime = "edge";

export async function POST(req: Request) {
    if (!genAI) {
        return new Response(JSON.stringify({ error: "Gemini API Key not configured" }), {
            status: 500,
            headers: { "Content-Type": "application/json" },
        });
    }

    try {
        const { messages } = await req.json();
        const lastMessage = messages[messages.length - 1];

        const model = genAI.getGenerativeModel({
            model: "gemini-2.0-flash-exp",
            systemInstruction: "You are a specialized financial assistant for a dashboard called 'Concierge'. Your goal is to help users register expenses and income. You should analyze their input and extract: Type (Expense/Income), Amount, Category, and Description. If the input is vague, ask for clarification. Maintain a luxurious, professional, and helpful tone. Format your response in Markdown."
        });

        const result = await model.generateContent(lastMessage.content);
        const response = await result.response;
        const text = response.text();

        return new Response(JSON.stringify({ content: text }), {
            status: 200,
            headers: { "Content-Type": "application/json" },
        });
    } catch (error) {
        console.error("Gemini API Error:", error);
        return new Response(JSON.stringify({ error: "Failed to fetch response" }), {
            status: 500,
            headers: { "Content-Type": "application/json" },
        });
    }
}
