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
        const { messages } = await req.json();
        const lastMessage = messages[messages.length - 1];

        const response = await genAI.models.generateContent({
            model: "gemini-2.0-flash",
            contents: lastMessage.content,
            config: {
                systemInstruction: "You are a specialized financial assistant for a dashboard called 'Concierge'. Your goal is to help users with financial questions and advice. Maintain a luxurious, professional, and helpful tone. Respond in Portuguese (Brazilian). Keep responses concise."
            }
        });

        const text = response.text;

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
