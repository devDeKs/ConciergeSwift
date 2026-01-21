"use client";

import { useEffect, useRef, useCallback, useTransition, useState } from "react";
import { cn } from "@/lib/utils";
import {
    CircleDollarSign,
    TrendingUp,
    TrendingDown,
    PieChart,
    Wallet,
    ArrowUpIcon,
    Paperclip,
    SendIcon,
    XIcon,
    LoaderIcon,
    Sparkles,
    Command,
    Calendar,
    ArrowLeft,
    CheckCircle2,
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import * as React from "react"
import { SidebarHistory } from "./sidebar-history";
import { FreeBalanceIndicator } from "./free-balance-indicator";
import { InstallmentModal } from "./installment-modal";
import { useTransactions } from "@/hooks/useTransactions";
import { useProfile } from "@/hooks/useProfile";
import { useAuth } from "@/contexts/AuthContext";
import { parseTransactionFromMessage, CreateTransactionInput } from "@/lib/transactions";
import { CreditCard, Home, Settings } from "lucide-react";
import { InteractiveMenu } from "./mobile-dock";

// Flowing Waves Background Animation
function FloatingPaths({ position }: { position: number }) {
    const paths = Array.from({ length: 24 }, (_, i) => {
        // Create flowing wave paths with sine-wave-like curves
        const yOffset = 80 + i * 12 * position;
        const amplitude = 30 + i * 3;
        const wavelength = 200 + i * 10;

        // Generate smooth wave path - extended for seamless loop
        const d = `M-100 ${yOffset} 
            Q${wavelength * 0.25} ${yOffset - amplitude} ${wavelength * 0.5} ${yOffset}
            T${wavelength} ${yOffset}
            T${wavelength * 1.5} ${yOffset}
            T${wavelength * 2} ${yOffset}
            T${wavelength * 2.5} ${yOffset}
            T${wavelength * 3} ${yOffset}
            T${wavelength * 3.5} ${yOffset}
            T${wavelength * 4} ${yOffset}
            T${wavelength * 4.5} ${yOffset}
            T${wavelength * 5} ${yOffset}`;

        return {
            id: i,
            d,
            width: 0.3 + i * 0.02,
            wavelength,
            // Staggered timing for organic flow - smoother entry
            duration: 10 + (i % 6) * 2,
            delay: i * 0.15, // Sequential stagger for smooth cascade entry
        };
    });

    return (
        <div className="absolute inset-0 pointer-events-none -translate-y-[10%]">
            <svg
                className="w-full h-full text-gold/60"
                viewBox="0 0 1200 400"
                fill="none"
                preserveAspectRatio="xMidYMid slice"
            >
                <title>Background Waves</title>
                {paths.map((path) => (
                    <motion.path
                        key={path.id}
                        d={path.d}
                        stroke="currentColor"
                        strokeWidth={path.width}
                        strokeLinecap="round"
                        initial={{
                            pathLength: 0,
                            pathOffset: 0,
                            opacity: 0,
                            strokeOpacity: 0,
                        }}
                        animate={{
                            pathLength: [0, 0.5, 0.3, 0.6, 0.4],
                            pathOffset: [0, 0.25, 0.5, 0.75, 1],
                            opacity: [0, 0.4, 0.3, 0.45, 0],
                            strokeOpacity: [0, 0.08 + path.id * 0.015, 0.1 + path.id * 0.01, 0.08 + path.id * 0.015, 0],
                        }}
                        transition={{
                            duration: path.duration,
                            repeat: Number.POSITIVE_INFINITY,
                            ease: "easeInOut",
                            delay: path.delay,
                            times: [0, 0.2, 0.5, 0.8, 1],
                        }}
                    />
                ))}
            </svg>
        </div>
    );
}

// Types for Chat
interface Message {
    role: "user" | "assistant";
    content: string;
}

interface UseAutoResizeTextareaProps {
    minHeight: number;
    maxHeight?: number;
}

function useAutoResizeTextarea({
    minHeight,
    maxHeight,
}: UseAutoResizeTextareaProps) {
    const textareaRef = useRef<HTMLTextAreaElement>(null);

    const adjustHeight = useCallback(
        (reset?: boolean) => {
            const textarea = textareaRef.current;
            if (!textarea) return;

            if (reset) {
                textarea.style.height = `${minHeight}px`;
                return;
            }

            textarea.style.height = `${minHeight}px`;
            const newHeight = Math.max(
                minHeight,
                Math.min(
                    textarea.scrollHeight,
                    maxHeight ?? Number.POSITIVE_INFINITY
                )
            );

            textarea.style.height = `${newHeight}px`;
        },
        [minHeight, maxHeight]
    );

    useEffect(() => {
        const textarea = textareaRef.current;
        if (textarea) {
            textarea.style.height = `${minHeight}px`;
        }
    }, [minHeight]);

    useEffect(() => {
        const handleResize = () => adjustHeight();
        window.addEventListener("resize", handleResize);
        return () => window.removeEventListener("resize", handleResize);
    }, [adjustHeight]);

    return { textareaRef, adjustHeight };
}

interface CommandSuggestion {
    icon: React.ReactNode;
    label: string;
    description: string;
    prefix: string;
}

interface TextareaProps
    extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
    containerClassName?: string;
    showRing?: boolean;
}

const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(
    ({ className, containerClassName, showRing = true, ...props }, ref) => {
        const [isFocused, setIsFocused] = React.useState(false);

        return (
            <div className={cn(
                "relative",
                containerClassName
            )}>
                <textarea
                    className={cn(
                        "flex min-h-[80px] w-full rounded-md border border-input/10 bg-midnight-light/30 px-3 py-2 text-sm",
                        "transition-all duration-200 ease-in-out",
                        "placeholder:text-white/20 text-white",
                        "disabled:cursor-not-allowed disabled:opacity-50",
                        showRing ? "focus-visible:outline-none focus-visible:ring-0 focus-visible:ring-offset-0" : "",
                        className
                    )}
                    ref={ref}
                    onFocus={() => setIsFocused(true)}
                    onBlur={() => setIsFocused(false)}
                    {...props}
                />

                {showRing && isFocused && (
                    <motion.span
                        className="absolute inset-0 rounded-md pointer-events-none ring-1 ring-offset-0 ring-gold/50"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        transition={{ duration: 0.2 }}
                    />
                )}

                {props.onChange && (
                    <div
                        className="absolute bottom-2 right-2 opacity-0 w-2 h-2 bg-gold rounded-full shadow-[0_0_8px_rgba(212,175,55,0.8)]"
                        style={{
                            animation: 'none',
                        }}
                        id="textarea-ripple"
                    />
                )}
            </div>
        )
    }
)
Textarea.displayName = "Textarea"

Textarea.displayName = "Textarea"

export function AnimatedAIChat() {
    // Data hooks
    const { user } = useAuth();
    const { addTransaction, refresh: refreshTransactions } = useTransactions();
    const { firstName, greetingPrefix } = useProfile();

    // Unified Menu State
    const [activeMenu, setActiveMenu] = useState<"main" | "reports" | "income" | "expense">("main");

    // State
    const [value, setValue] = useState("");
    const [attachments, setAttachments] = useState<string[]>([]);
    const [isTyping, setIsTyping] = useState(false);
    const [isPending, startTransition] = useTransition();
    const [activeSuggestion, setActiveSuggestion] = useState<number>(-1);
    const [showCommandPalette, setShowCommandPalette] = useState(false);
    const [recentCommand, setRecentCommand] = useState<string | null>(null);
    const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });
    const [messages, setMessages] = useState<Message[]>([]);
    const [transactionSuccess, setTransactionSuccess] = useState<string | null>(null);

    // Auto-scroll ref
    const messagesEndRef = useRef<HTMLDivElement>(null);

    // Auto-scroll to bottom
    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    };

    useEffect(() => {
        scrollToBottom();
    }, [messages, isTyping]);

    // Installment Modal State
    const [showInstallmentModal, setShowInstallmentModal] = useState(false);

    // ... (Subtitle logic remains same)
    const [currentTipIndex, setCurrentTipIndex] = useState(0);
    const financeTips = ["Gaste menos do que ganha.", "Crie um fundo de emergência.", "Evite dívidas de cartão de crédito.", "Invista pensando no longo prazo.", "Compare preços antes de comprar.", "Defina metas financeiras claras.", "Revise seus gastos mensalmente.", "Pague suas contas em dia.", "Diversifique seus investimentos.", "Aprenda sobre juros compostos.", "Use a regra 50-30-20.", "Negocie suas dívidas.", "Evite compras por impulso.", "Tenha várias fontes de renda.", "Planeje sua aposentadoria cedo.", "Mantenha seu estilo de vida simples.", "Acompanhe seu score de crédito.", "Reinvista seus dividendos.", "Faça um orçamento anual.", "Eduque-se financeiramente sempre."];

    useEffect(() => {
        const interval = setInterval(() => {
            setCurrentTipIndex((prev) => (prev + 1) % financeTips.length);
        }, 5000);
        return () => clearInterval(interval);
    }, [financeTips.length]);

    // Sidebar State
    const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);

    const { textareaRef, adjustHeight } = useAutoResizeTextarea({ minHeight: 60, maxHeight: 200 });
    const [inputFocused, setInputFocused] = useState(false);
    const commandPaletteRef = useRef<HTMLDivElement>(null);

    // --- Suggestion Data Arrays ---
    const mainOptions: CommandSuggestion[] = [
        { icon: <TrendingUp className="w-5 h-5 text-emerald-400" />, label: "Receita", description: "Registrar ganho", prefix: "income_menu" },
        { icon: <TrendingDown className="w-5 h-5 text-rose-400" />, label: "Despesa", description: "Registrar gasto", prefix: "expense_menu" },
        { icon: <CreditCard className="w-5 h-5 text-blue-400" />, label: "Parcelas", description: "Parcelamento", prefix: "installments_menu" },
        { icon: <PieChart className="w-5 h-5 text-gold" />, label: "Relatório", description: "Ver resumo", prefix: "reports_menu" },
    ];

    const reportOptions: CommandSuggestion[] = [
        { icon: <Calendar className="w-5 h-5 text-gold" />, label: "7 Dias", description: "Última semana", prefix: "Gerar relatório dos últimos 7 dias" },
        { icon: <Calendar className="w-5 h-5 text-gold" />, label: "30 Dias", description: "Último mês", prefix: "Gerar relatório dos últimos 30 dias" },
        { icon: <PieChart className="w-5 h-5 text-emerald-400" />, label: "Categorias", description: "Por categoria", prefix: "Gerar relatório de gastos por categoria" },
        { icon: <TrendingUp className="w-5 h-5 text-blue-400" />, label: "Receitas", description: "Fontes de renda", prefix: "Gerar relatório de receitas" }
    ];

    const incomeOptions: CommandSuggestion[] = [
        { icon: <Wallet className="w-5 h-5 text-emerald-400" />, label: "Salário", description: "Renda mensal", prefix: "Recebi R$ [valor] de Salário" },
        { icon: <Sparkles className="w-5 h-5 text-yellow-400" />, label: "Freelance", description: "Trabalho extra", prefix: "Recebi R$ [valor] de Freelance" },
        { icon: <TrendingUp className="w-5 h-5 text-blue-400" />, label: "Investimento", description: "Rendimentos", prefix: "Recebi R$ [valor] de Investimentos" },
        { icon: <CircleDollarSign className="w-5 h-5 text-white/60" />, label: "Outros", description: "Diversos", prefix: "Recebi R$ [valor] de Outros" }
    ];

    const expenseOptions: CommandSuggestion[] = [
        { icon: <TrendingDown className="w-5 h-5 text-rose-400" />, label: "Alimentação", description: "Mercado/iFood", prefix: "Gastei R$ [valor] com Alimentação" },
        { icon: <Wallet className="w-5 h-5 text-blue-400" />, label: "Transporte", description: "Uber/Combustível", prefix: "Gastei R$ [valor] com Transporte" },
        { icon: <Sparkles className="w-5 h-5 text-purple-400" />, label: "Lazer", description: "Entretenimento", prefix: "Gastei R$ [valor] com Lazer" },
        { icon: <CircleDollarSign className="w-5 h-5 text-white/60" />, label: "Outros", description: "Diversos", prefix: "Gastei R$ [valor] com Outros" }
    ];

    // Helper to get current options
    const getCurrentOptions = () => {
        switch (activeMenu) {
            case "reports": return reportOptions;
            case "income": return incomeOptions;
            case "expense": return expenseOptions;
            default: return mainOptions;
        }
    }

    // ... (useEffect for command palette remains same)
    useEffect(() => {
        // Simple command palette logic only for main chat input commands
        if (value.startsWith('/') && !value.includes(' ')) {
            setShowCommandPalette(true);
            const matchingSuggestionIndex = mainOptions.findIndex(cmd => cmd.prefix.startsWith(value)); // simplified
            if (matchingSuggestionIndex >= 0) setActiveSuggestion(matchingSuggestionIndex);
            else setActiveSuggestion(-1);
        } else {
            setShowCommandPalette(false);
        }
    }, [value]);

    useEffect(() => { const handleMouseMove = (e: MouseEvent) => { setMousePosition({ x: e.clientX, y: e.clientY }); }; window.addEventListener('mousemove', handleMouseMove); return () => { window.removeEventListener('mousemove', handleMouseMove); }; }, []);
    useEffect(() => { const handleClickOutside = (event: MouseEvent) => { const target = event.target as Node; const commandButton = document.querySelector('[data-command-button]'); if (commandPaletteRef.current && !commandPaletteRef.current.contains(target) && !commandButton?.contains(target)) { setShowCommandPalette(false); } }; document.addEventListener('mousedown', handleClickOutside); return () => { document.removeEventListener('mousedown', handleClickOutside); }; }, []);

    const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
        // ... (Simplified KeyDown for brevity, logic remains for palette)
        if (showCommandPalette) {
            if (e.key === 'ArrowDown') { e.preventDefault(); setActiveSuggestion(prev => prev < mainOptions.length - 1 ? prev + 1 : 0); }
            else if (e.key === 'ArrowUp') { e.preventDefault(); setActiveSuggestion(prev => prev > 0 ? prev - 1 : mainOptions.length - 1); }
            else if (e.key === 'Tab' || e.key === 'Enter') {
                e.preventDefault();
                if (activeSuggestion >= 0) {
                    const selected = mainOptions[activeSuggestion];
                    // Handle menu switching via keyboard if needed, or just insert text
                    if (selected.prefix.endsWith("_menu")) {
                        if (selected.label === "Receita") setActiveMenu("income");
                        if (selected.label === "Despesa") setActiveMenu("expense");
                        if (selected.label === "Relatório") setActiveMenu("reports");
                    } else {
                        setValue(selected.prefix + ' ');
                    }
                    setShowCommandPalette(false);
                }
            } else if (e.key === 'Escape') { e.preventDefault(); setShowCommandPalette(false); }
        } else if (e.key === "Enter" && !e.shiftKey) {
            e.preventDefault();
            if (value.trim()) handleSendMessage();
        }
    };

    const handleSendMessage = async () => {
        if (!value.trim()) return;

        const messageContent = value.trim();
        setValue("");
        adjustHeight(true);
        setIsTyping(true);

        // Try to parse as transaction first
        const parsedTransaction = parseTransactionFromMessage(messageContent);

        // Format user message - if it's a transaction, show clean summary
        let displayMessage = messageContent;
        if (parsedTransaction && !isNaN(parsedTransaction.amount) && parsedTransaction.amount > 0) {
            const sign = parsedTransaction.type === 'expense' ? '-' : '+';
            // Capitalize first letter of description
            const desc = parsedTransaction.description.charAt(0).toUpperCase() + parsedTransaction.description.slice(1);
            displayMessage = `${desc} ${sign}R$${parsedTransaction.amount.toFixed(2)}`;
        }

        const userMessage: Message = { role: "user", content: displayMessage };
        setMessages(prev => [...prev, userMessage]);

        if (parsedTransaction) {
            // Check if user is logged in
            if (!user) {
                setMessages(prev => [...prev, {
                    role: "assistant",
                    content: "🔐 Para salvar transações, você precisa estar logado. Crie uma conta ou faça login para começar a gerenciar suas finanças!"
                }]);
                setIsTyping(false);
                return;
            }

            // It's a transaction - save to Supabase
            try {
                const result = await addTransaction(parsedTransaction);

                if (result.success) {
                    // Show success message
                    const typeLabel = parsedTransaction.type === 'income' ? 'Receita' : 'Despesa';
                    const successMsg = `✅ ${typeLabel} registrada: R$ ${parsedTransaction.amount.toFixed(2)} - ${parsedTransaction.description} (${parsedTransaction.category})`;

                    setMessages(prev => [...prev, { role: "assistant", content: successMsg }]);
                    setTransactionSuccess(successMsg);

                    // Refresh transactions in sidebar
                    refreshTransactions();

                    // Clear success after 3 seconds
                    setTimeout(() => setTransactionSuccess(null), 3000);
                } else {
                    setMessages(prev => [...prev, { role: "assistant", content: "Não foi possível salvar a transação. Por favor, tente novamente." }]);
                }
            } catch (error) {
                console.error('Transaction error:', error);
                setMessages(prev => [...prev, { role: "assistant", content: "Erro ao processar transação. Verifique sua conexão." }]);
            } finally {
                setIsTyping(false);
            }
        } else {
            // Regex didn't match - try AI parsing with Gemini
            startTransition(async () => {
                try {
                    // Try AI-powered transaction parsing first
                    const parseResponse = await fetch('/api/parse-transaction', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ message: messageContent })
                    });

                    if (parseResponse.ok) {
                        const parseResult = await parseResponse.json();

                        // Check if AI successfully parsed a transaction
                        if (parseResult.type && parseResult.amount && !parseResult.error) {
                            const aiTransaction = {
                                type: parseResult.type as 'income' | 'expense',
                                amount: parseResult.amount,
                                description: parseResult.description || 'Transação',
                                category: parseResult.category || 'Outros'
                            };

                            // Update displayed message with clean format
                            const sign = aiTransaction.type === 'expense' ? '-' : '+';
                            const cleanDisplay = `${aiTransaction.description} ${sign}R$${aiTransaction.amount.toFixed(2)}`;

                            // Update the last user message to show clean format
                            setMessages(prev => {
                                const updated = [...prev];
                                if (updated.length > 0 && updated[updated.length - 1].role === 'user') {
                                    updated[updated.length - 1].content = cleanDisplay;
                                }
                                return updated;
                            });

                            // Check if user is logged in
                            if (!user) {
                                setMessages(prev => [...prev, {
                                    role: "assistant",
                                    content: "🔐 Para salvar transações, você precisa estar logado. Crie uma conta ou faça login para começar a gerenciar suas finanças!"
                                }]);
                                setIsTyping(false);
                                return;
                            }

                            // Save the AI-parsed transaction
                            const result = await addTransaction(aiTransaction);

                            if (result.success) {
                                const typeLabel = aiTransaction.type === 'income' ? 'Receita' : 'Despesa';
                                const successMsg = `✅ ${typeLabel} registrada: R$ ${aiTransaction.amount.toFixed(2)} - ${aiTransaction.description} (${aiTransaction.category})`;
                                setMessages(prev => [...prev, { role: "assistant", content: successMsg }]);
                                setTransactionSuccess(successMsg);
                                refreshTransactions();
                                setTimeout(() => setTransactionSuccess(null), 3000);
                            } else {
                                setMessages(prev => [...prev, { role: "assistant", content: "Não foi possível salvar a transação. Por favor, tente novamente." }]);
                            }
                            setIsTyping(false);
                            return;
                        }
                    }

                    // Not a transaction - use general AI chat
                    const response = await fetch('/api/chat', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ messages: [...messages, userMessage] })
                    });
                    if (!response.ok) throw new Error('Failed to fetch');
                    const data = await response.json();
                    setMessages(prev => [...prev, { role: "assistant", content: data.content || "Peço desculpas, mas não consegui processar sua solicitação." }]);
                } catch (error) {
                    console.error(error);
                    setMessages(prev => [...prev, { role: "assistant", content: "Desculpe, estou com dificuldades para conectar ao serviço de concierge no momento." }]);
                } finally { setIsTyping(false); }
            });
        }
    };

    const handleAttachFile = () => { setAttachments(prev => [...prev, `invoice-${Math.floor(Math.random() * 1000)}.pdf`]); };
    const removeAttachment = (index: number) => { setAttachments(prev => prev.filter((_, i) => i !== index)); };

    const handleMenuSelection = (index: number) => {
        const options = getCurrentOptions();
        const selected = options[index];

        // Menu Navigation
        if (selected.prefix === "income_menu") { setActiveMenu("income"); return; }
        if (selected.prefix === "expense_menu") { setActiveMenu("expense"); return; }
        if (selected.prefix === "reports_menu") { setActiveMenu("reports"); return; }
        if (selected.prefix === "installments_menu") { setShowInstallmentModal(true); return; }

        // Final Action: Populate text and reset menu
        setValue(selected.prefix);
        setActiveMenu("main");

        // Optional: Auto-focus the textarea or selection
        if (textareaRef.current) {
            textareaRef.current.focus();
            // TODO: Ideally we'd select the "[valor]" part, but simple focus is good for now.
        }
    };

    return (
        // Use h-[100dvh] for mobile viewport stability
        <div className="flex flex-col h-[100dvh] bg-gradient-to-b from-midnight to-midnight-light relative overflow-hidden">
            {/* Gold Light Points - Soft & Faded */}
            <div className="absolute top-0 right-0 w-[500px] h-[500px] pointer-events-none opacity-40">
                <div className="absolute inset-0 bg-gradient-radial from-gold/30 via-gold/5 to-transparent blur-[100px]" />
            </div>
            <div className="absolute bottom-32 right-0 w-[400px] h-[400px] pointer-events-none opacity-30">
                <div className="absolute inset-0 bg-gradient-radial from-gold/25 via-gold/5 to-transparent blur-[90px]" />
            </div>

            {/* Main Content - Centered */}
            <div className="flex-1 flex flex-col items-center justify-center px-6 relative z-10 pt-[calc(5rem+env(safe-area-inset-top))]">
                {messages.length === 0 && (
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.6 }}
                        className="flex flex-col items-center text-center w-full max-w-md"
                    >
                        {/* Chat Mold/Placeholder Visual */}
                        <div className="relative w-48 h-32 mb-8 opacity-40 grayscale-[0.5]">
                            {/* Abstract Chat Bubbles */}
                            <motion.div
                                className="absolute top-0 right-4 w-28 h-10 bg-white/10 rounded-2xl rounded-tr-sm border border-white/10 flex items-center gap-2 px-3"
                                animate={{ y: [0, -5, 0] }}
                                transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
                            >
                                <div className="w-12 h-1.5 bg-white/20 rounded-full" />
                            </motion.div>

                            <motion.div
                                className="absolute top-14 left-0 w-32 h-12 bg-gold/10 rounded-2xl rounded-tl-sm border border-gold/10 flex items-center gap-2 px-3"
                                animate={{ y: [0, 5, 0] }}
                                transition={{ duration: 5, repeat: Infinity, ease: "easeInOut", delay: 1 }}
                            >
                                <div className="w-16 h-1.5 bg-gold/20 rounded-full" />
                            </motion.div>

                            <motion.div
                                className="absolute bottom-0 right-8 w-24 h-9 bg-white/10 rounded-2xl rounded-br-sm border border-white/10 flex items-center gap-2 px-3"
                                animate={{ y: [0, -3, 0] }}
                                transition={{ duration: 4.5, repeat: Infinity, ease: "easeInOut", delay: 0.5 }}
                            >
                                <div className="w-10 h-1.5 bg-white/20 rounded-full" />
                            </motion.div>
                        </div>

                        {/* Greeting Messages - Perfectly Centered */}
                        <div className="space-y-3">
                            <h1
                                className="text-3xl md:text-4xl font-serif text-white tracking-wide"
                                style={{ fontFamily: 'var(--font-playfair)' }}
                            >
                                Bom ver você de volta!
                            </h1>
                            <h2 className="text-lg md:text-xl text-white/70 font-light max-w-xs mx-auto leading-relaxed">
                                Como posso ajudar você hoje?
                            </h2>
                        </div>
                    </motion.div>
                )}
            </div>

            {/* Chat Messages Area - Flexible Middle */}
            <div className="flex-1 overflow-y-auto px-6 py-4 scrollbar-none z-10 w-full">
                {messages.length > 0 && (
                    <div className="w-full max-w-2xl mx-auto space-y-4">
                        {messages.map((msg, idx) => (
                            <motion.div
                                key={idx}
                                initial={{ opacity: 0, scale: 0.95 }}
                                animate={{ opacity: 1, scale: 1 }}
                                className={cn(
                                    "p-4 rounded-2xl max-w-[85%] backdrop-blur-md",
                                    msg.role === "user"
                                        ? "ml-auto bg-gold/20 border border-gold/30 text-white"
                                        : "mr-auto bg-white/10 border border-white/10 text-white/90"
                                )}
                            >
                                {msg.content}
                            </motion.div>
                        ))}
                        {isTyping && (
                            <div className="mr-auto bg-white/10 border border-white/10 rounded-2xl p-4 w-16 h-10 flex items-center justify-center">
                                <TypingDots />
                            </div>
                        )}
                        <div ref={messagesEndRef} />
                    </div>
                )}
            </div>

            {/* Input Section - White Bottom Sheet */}
            <div className="flex-none bg-white rounded-t-[2.5rem] shadow-[0_-10px_40px_rgba(0,0,0,0.2)] z-20 pb-[calc(6rem+env(safe-area-inset-bottom))]">
                <div className="max-w-2xl mx-auto px-6 pt-6">
                    {/* Templates / Suggestions */}
                    {messages.length === 0 && (
                        <div className="flex gap-2 mb-6 overflow-x-auto pb-2 scrollbar-none">
                            {getCurrentOptions().map((suggestion, index) => (
                                <motion.button
                                    key={suggestion.label}
                                    initial={{ opacity: 0, y: 10 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    transition={{ delay: 0.1 * index }}
                                    onClick={() => handleMenuSelection(index)}
                                    className="flex items-center gap-2 px-4 py-3 rounded-2xl bg-gray-50 border border-gray-100 text-gray-600 hover:bg-gold/5 hover:border-gold/20 hover:text-gold text-sm font-medium transition-all whitespace-nowrap"
                                >
                                    <span className="text-gold">{suggestion.icon}</span>
                                    <span>{suggestion.label}</span>
                                </motion.button>
                            ))}
                        </div>
                    )}

                    {/* Input Bar */}
                    <div className="relative flex items-center gap-3">
                        <div className="flex-1 bg-gray-50 rounded-2xl flex items-center px-4 py-3 border border-gray-200 focus-within:border-gold/50 focus-within:bg-white transition-all">
                            <input
                                type="text"
                                value={value}
                                onChange={(e) => setValue(e.target.value)}
                                onKeyDown={(e) => {
                                    if (e.key === 'Enter' && !e.shiftKey) {
                                        e.preventDefault();
                                        handleSendMessage();
                                    }
                                }}
                                onFocus={() => setInputFocused(true)}
                                onBlur={() => setInputFocused(false)}
                                placeholder="Registre suas finanças..."
                                className="flex-1 bg-transparent border-none text-gray-900 text-[15px] placeholder:text-gray-400 focus:outline-none"
                            />
                            <div className="flex items-center gap-2 pl-2 border-l border-gray-200 ml-2">
                                <button className="p-1.5 text-gray-400 hover:text-gold transition-colors rounded-lg hover:bg-gray-100">
                                    <Paperclip className="w-5 h-5" />
                                </button>
                                <button
                                    onClick={() => setShowCommandPalette(prev => !prev)}
                                    className="p-1.5 text-gray-400 hover:text-gold transition-colors rounded-lg hover:bg-gray-100"
                                >
                                    <Command className="w-5 h-5" />
                                </button>
                            </div>
                        </div>

                        <motion.button
                            onClick={handleSendMessage}
                            whileTap={{ scale: 0.9 }}
                            disabled={!value.trim() && !isTyping}
                            className={cn(
                                "w-12 h-12 rounded-2xl flex items-center justify-center transition-all shadow-lg",
                                value.trim()
                                    ? "bg-gold text-white hover:bg-gold-light hover:shadow-gold/30"
                                    : "bg-gray-100 text-gray-300"
                            )}
                        >
                            {isTyping ? (
                                <LoaderIcon className="w-5 h-5 animate-spin" />
                            ) : (
                                <SendIcon className="w-5 h-5 ml-0.5" />
                            )}
                        </motion.button>
                    </div>
                </div>
            </div>

            {/* Installment Modal */}
            <InstallmentModal
                isOpen={showInstallmentModal}
                onClose={() => setShowInstallmentModal(false)}
                onConfirm={(installments) => {
                    console.log('Created installments:', installments)
                    refreshTransactions()
                }}
            />
        </div>
    );
}

function TypingDots() {
    return (
        <div className="flex items-center ml-1">
            {[1, 2, 3].map((dot) => (
                <motion.div
                    key={dot}
                    className="w-1.5 h-1.5 bg-gold/90 rounded-full mx-0.5"
                    initial={{ opacity: 0.3 }}
                    animate={{
                        opacity: [0.3, 0.9, 0.3],
                        scale: [0.85, 1.1, 0.85]
                    }}
                    transition={{
                        duration: 1.2,
                        repeat: Infinity,
                        delay: dot * 0.15,
                        ease: "easeInOut",
                    }}
                    style={{
                        boxShadow: "0 0 4px rgba(212, 175, 55, 0.3)"
                    }}
                />
            ))}
        </div>
    );
}
