import { cn } from "@/lib/utils";
import { motion, AnimatePresence } from "framer-motion";
import {
    History, ChevronLeft, Search, ArrowUpRight, ArrowDownRight,
    Filter, PanelLeftClose, PanelLeftOpen, PieChart, BarChart3,
    Settings, User, Shield, Trash2, LogOut, CheckCircle2,
    Wallet, TrendingUp, CreditCard, Download
} from "lucide-react";
import { useState, useMemo } from "react";

// --- Types ---
interface Transaction {
    id: string;
    description: string;
    amount: number;
    type: "income" | "expense";
    date: string;
    dateTime: Date;
    category: string;
}

// --- Mock Data ---
const mockHistory: Transaction[] = [
    { id: "1", description: "Supermercado Semanal", amount: 450.50, type: "expense", date: "Hoje, 10:30", dateTime: new Date(), category: "Alimentação" },
    { id: "2", description: "Pagamento Freelance", amount: 3200.00, type: "income", date: "Ontem, 16:20", dateTime: new Date(Date.now() - 86400000), category: "Trabalho" },
    { id: "3", description: "Assinatura Netflix", amount: 55.90, type: "expense", date: "20 Dez", dateTime: new Date(Date.now() - 86400000 * 2), category: "Lazer" },
    { id: "4", description: "Uber Viagem", amount: 24.30, type: "expense", date: "19 Dez", dateTime: new Date(Date.now() - 86400000 * 3), category: "Transporte" },
    { id: "5", description: "Reembolso Médico", amount: 150.00, type: "income", date: "18 Dez", dateTime: new Date(Date.now() - 86400000 * 4), category: "Saúde" },
    { id: "6", description: "Jantar Fora", amount: 120.00, type: "expense", date: "17 Dez", dateTime: new Date(Date.now() - 86400000 * 5), category: "Alimentação" },
    { id: "7", description: "Combustível", amount: 200.00, type: "expense", date: "16 Dez", dateTime: new Date(Date.now() - 86400000 * 6), category: "Transporte" },
    { id: "8", description: "Venda Online", amount: 150.00, type: "income", date: "15 Dez", dateTime: new Date(Date.now() - 86400000 * 7), category: "Vendas" },
];

// --- Components ---

// 1. Simple SVG Pie Chart
const SimplePieChart = ({ data }: { data: { label: string, value: number, color: string }[] }) => {
    const total = data.reduce((acc, curr) => acc + curr.value, 0);
    let currentAngle = 0;

    return (
        <div className="relative w-40 h-40 mx-auto">
            <svg viewBox="0 0 100 100" className="transform -rotate-90 w-full h-full">
                {data.map((slice, i) => {
                    const sliceAngle = (slice.value / total) * 360;
                    const x1 = 50 + 50 * Math.cos(Math.PI * currentAngle / 180);
                    const y1 = 50 + 50 * Math.sin(Math.PI * currentAngle / 180);
                    const x2 = 50 + 50 * Math.cos(Math.PI * (currentAngle + sliceAngle) / 180);
                    const y2 = 50 + 50 * Math.sin(Math.PI * (currentAngle + sliceAngle) / 180);

                    const pathData = slice.value === total
                        ? `M 50 50 m -50, 0 a 50,50 0 1,0 100,0 a 50,50 0 1,0 -100,0` // Full circle
                        : `M 50 50 L ${x1} ${y1} A 50 50 0 ${sliceAngle > 180 ? 1 : 0} 1 ${x2} ${y2} Z`;

                    currentAngle += sliceAngle;

                    return (
                        <motion.path
                            key={i}
                            d={pathData}
                            fill={slice.color}
                            initial={{ opacity: 0, scale: 0.8 }}
                            animate={{ opacity: 1, scale: 1 }}
                            transition={{ delay: i * 0.1, duration: 0.5 }}
                            className="hover:opacity-80 transition-opacity cursor-pointer"
                        />
                    );
                })}
            </svg>
            <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                <div className="w-24 h-24 bg-midnight rounded-full flex flex-col items-center justify-center">
                    <span className="text-[10px] text-white/40">Total</span>
                    <span className="text-xs font-bold text-white">R$ {total.toLocaleString('pt-BR', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}</span>
                </div>
            </div>
        </div>
    );
};

// 2. Simple Liquid/Bar Chart
const LiquidChart = ({ percentage, color = "#D4AF37" }: { percentage: number, color?: string }) => {
    return (
        <div className="w-16 h-32 bg-white/5 rounded-full relative overflow-hidden ring-1 ring-white/10 mx-auto">
            <motion.div
                className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-current to-transparent opacity-50"
                style={{ color, height: `${percentage}%` }}
                animate={{ height: [`${percentage}%`, `${percentage - 5}%`, `${percentage}%`] }}
                transition={{ repeat: Infinity, duration: 3, ease: "easeInOut" }}
            />
            <motion.div
                className="absolute bottom-0 left-0 right-0"
                style={{ backgroundColor: color, height: `${percentage}%` }}
                initial={{ height: 0 }}
                animate={{ height: `${percentage}%` }}
                transition={{ duration: 1.5, type: "spring" }}
            >
                <div className="absolute top-0 w-full h-2 bg-white/20 blur-[2px]" />
            </motion.div>
            <div className="absolute inset-0 flex items-center justify-center text-xs font-bold text-white z-10 mix-blend-difference">
                {percentage}%
            </div>
        </div>
    );
};

export function SidebarHistory() {
    // UI State
    const [isOpen, setIsOpen] = useState(false); // Mobile
    const [isCollapsed, setIsCollapsed] = useState(false); // Desktop
    const [activeTab, setActiveTab] = useState<"home" | "analytics" | "settings">("home");
    const [chartType, setChartType] = useState<"pie" | "liquid">("pie");

    // Filter Logic (Kept basic for 'home' tab)
    const [categoryFilter, setCategoryFilter] = useState("Todas");

    // Derived Data
    const categories = ["Todas", ...new Set(mockHistory.map(item => item.category))];
    const recentTransactions = useMemo(() => mockHistory.slice(0, 5), []);

    // Analytics Data Calculation
    const stats = useMemo(() => {
        const totalIncome = mockHistory.filter(t => t.type === 'income').reduce((acc, curr) => acc + curr.amount, 0);
        const totalExpense = mockHistory.filter(t => t.type === 'expense').reduce((acc, curr) => acc + curr.amount, 0);
        const balance = totalIncome - totalExpense;
        const savingsRate = totalIncome > 0 ? Math.round(((totalIncome - totalExpense) / totalIncome) * 100) : 0;

        // Category Data for Pie Chart
        const catData = Object.entries(
            mockHistory.filter(t => t.type === 'expense').reduce((acc, curr) => {
                acc[curr.category] = (acc[curr.category] || 0) + curr.amount;
                return acc;
            }, {} as Record<string, number>)
        ).map(([label, value], i) => ({
            label, value, color: [`#ef4444`, `#f59e0b`, `#3b82f6`, `#10b981`, `#8b5cf6`][i % 5]
        }));

        return { totalIncome, totalExpense, balance, savingsRate, catData };
    }, []);

    return (
        <>
            {/* Mobile Toggle */}
            <div className="md:hidden fixed top-4 left-4 z-50">
                <button
                    onClick={() => setIsOpen(!isOpen)}
                    className="p-2 bg-midnight-light/50 border border-white/10 rounded-lg text-white"
                >
                    <History className="w-5 h-5" />
                </button>
            </div>

            {/* Backdrop */}
            <AnimatePresence>
                {isOpen && (
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        onClick={() => setIsOpen(false)}
                        className="fixed inset-0 bg-black/60 backdrop-blur-sm z-40 md:hidden"
                    />
                )}
            </AnimatePresence>

            {/* Sidebar Container */}
            <motion.div
                className={cn(
                    "fixed top-0 left-0 h-full bg-midnight/95 backdrop-blur-xl border-r border-white/5 z-50 shadow-2xl font-sans overflow-hidden flex flex-col",
                    isOpen ? "translate-x-0" : "-translate-x-full md:translate-x-0"
                )}
                animate={{ width: isCollapsed ? 80 : 320 }}
                transition={{ duration: 0.4, ease: [0.32, 0.72, 0, 1] }}
            >
                {/* --- HEADER --- */}
                <div className="h-[80px] border-b border-white/5 flex items-center justify-between shrink-0 relative px-6 w-[320px] box-border">
                    <div className="flex items-center gap-4"> {/* Align with Left Padding */}
                        <div className="w-8 h-8 flex items-center justify-center relative shrink-0">
                            {/* Standard Icon */}
                            <motion.div animate={{ opacity: isCollapsed ? 0 : 1 }} className="absolute inset-0 flex items-center justify-center">
                                {activeTab === "home" && <History className="w-5 h-5 text-gold" />}
                                {activeTab === "analytics" && <PieChart className="w-5 h-5 text-gold" />}
                                {activeTab === "settings" && <Settings className="w-5 h-5 text-gold" />}
                            </motion.div>
                            {/* Expand Button (Visible when collapsed) */}
                            <motion.button
                                onClick={() => setIsCollapsed(false)}
                                animate={{ opacity: isCollapsed ? 1 : 0, pointerEvents: isCollapsed ? 'auto' : 'none' }}
                                className="absolute inset-0 flex items-center justify-center text-white/40 hover:text-white transition-colors"
                            >
                                <PanelLeftOpen className="w-5 h-5" />
                            </motion.button>
                        </div>
                        <motion.h2
                            className="text-sm font-medium tracking-wide text-white/90 font-serif whitespace-nowrap origin-left"
                            animate={{ opacity: isCollapsed ? 0 : 1, filter: isCollapsed ? "blur(10px)" : "blur(0px)", x: isCollapsed ? -10 : 0 }}
                        >
                            {activeTab === "home" ? "HISTÓRICO" : activeTab === "analytics" ? "ANÁLISE" : "CONFIGURAÇÕES"}
                        </motion.h2>
                    </div>
                    {/* Minimize Button */}
                    <motion.button onClick={() => setIsCollapsed(true)} animate={{ opacity: isCollapsed ? 0 : 1 }} className="hidden md:flex text-white/40 hover:text-white transition-colors">
                        <PanelLeftClose className="w-5 h-5" />
                    </motion.button>
                    <button onClick={() => setIsOpen(false)} className="md:hidden text-white/40"><ChevronLeft className="w-5 h-5" /></button>
                </div>

                {/* --- MAIN CONTENT (SCROLLABLE) --- */}
                <div className="flex-1 overflow-x-hidden overflow-y-auto scrollbar-none w-[320px]">

                    {/* HOME TAB: RECENT TRANSACTIONS */}
                    {activeTab === "home" && (
                        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="p-0">
                            <div className="px-6 py-4 space-y-3 w-[320px]">
                                <div className="relative h-9 flex items-center">
                                    {/* Fixed Search Icon aligned with Header Icon (using padding-left) */}
                                    <div className="absolute left-0 w-8 h-full flex items-center justify-center z-10 pointer-events-none">
                                        <Search className="w-3.5 h-3.5 text-white/30" />
                                    </div>
                                    <motion.input
                                        type="text"
                                        placeholder="Buscar..."
                                        className="w-full bg-white/[0.03] border border-white/5 rounded-lg pl-9 pr-3 py-2 text-xs text-white focus:outline-none focus:border-gold/30 transition-all origin-left"
                                        animate={{ opacity: isCollapsed ? 0 : 1, filter: isCollapsed ? "blur(4px)" : "blur(0px)" }}
                                    />
                                </div>
                                <motion.div
                                    className="flex items-center justify-between text-[10px] text-white/40 uppercase tracking-wider font-medium pl-1"
                                    animate={{ opacity: isCollapsed ? 0 : 1, filter: isCollapsed ? "blur(4px)" : "blur(0px)" }}
                                >
                                    <span>Recentes ({recentTransactions.length})</span>
                                    <span className="text-gold cursor-pointer hover:underline">Ver Todos</span>
                                </motion.div>
                            </div>

                            <div className="px-6 pb-4 space-y-2 w-[320px]">
                                {recentTransactions.map((item) => (
                                    <motion.div
                                        key={item.id}
                                        layoutId={item.id}
                                        className="group flex items-center gap-4 p-2 -ml-2 rounded-xl hover:bg-white/[0.03] border border-transparent hover:border-white/5 transition-colors cursor-pointer"
                                    >
                                        <div className={cn("w-8 h-8 rounded-full flex items-center justify-center border shrink-0 transition-colors", item.type === "income" ? "bg-emerald-500/10 border-emerald-500/20 text-emerald-400" : "bg-rose-500/10 border-rose-500/20 text-rose-400")}>
                                            {item.type === "income" ? <ArrowUpRight className="w-3.5 h-3.5" /> : <ArrowDownRight className="w-3.5 h-3.5" />}
                                        </div>
                                        <motion.div
                                            animate={{ opacity: isCollapsed ? 0 : 1, filter: isCollapsed ? "blur(6px)" : "blur(0px)", x: isCollapsed ? -10 : 0 }}
                                            transition={{ duration: 0.3 }}
                                            className="flex-1 min-w-0"
                                        >
                                            <div className="flex items-center justify-between mb-0.5">
                                                <span className="text-sm text-white/90 truncate font-medium">{item.description}</span>
                                                <span className={cn("text-xs font-mono", item.type === "income" ? "text-emerald-400" : "text-white/70")}>
                                                    {item.type === "income" ? "+" : "-"} {item.amount.toLocaleString('pt-BR', { minimumFractionDigits: 0 })}
                                                </span>
                                            </div>
                                            <div className="flex items-center justify-between text-[10px] text-white/40"><span>{item.category}</span><span>{item.date}</span></div>
                                        </motion.div>
                                    </motion.div>
                                ))}
                            </div>

                            {/* Summary Card */}
                            <motion.div
                                className="px-6 py-4 w-[320px]"
                                animate={{ opacity: isCollapsed ? 0 : 1, filter: isCollapsed ? "blur(8px)" : "blur(0px)", pointerEvents: isCollapsed ? 'none' : 'auto' }}
                            >
                                <div className="p-4 rounded-xl bg-gradient-to-br from-midnight-light/50 to-midnight-light/10 border border-white/5 relative overflow-hidden">
                                    <div className="relative z-10">
                                        <div className="text-xs text-white/50 mb-1">Saldo Atual</div>
                                        <div className="text-2xl font-serif text-white mb-3">R$ {stats.balance.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}</div>
                                        <div className="flex gap-2">
                                            <div className="flex-1 bg-white/5 rounded-lg p-2">
                                                <div className="text-[10px] text-emerald-400 mb-0.5 flex items-center gap-1"><ArrowUpRight className="w-3 h-3" /> Entradas</div>
                                                <div className="text-xs font-medium text-white/80">{stats.totalIncome.toLocaleString('pt-BR', { compactDisplay: "short", notation: "compact" })}</div>
                                            </div>
                                            <div className="flex-1 bg-white/5 rounded-lg p-2">
                                                <div className="text-[10px] text-rose-400 mb-0.5 flex items-center gap-1"><ArrowDownRight className="w-3 h-3" /> Saídas</div>
                                                <div className="text-xs font-medium text-white/80">{stats.totalExpense.toLocaleString('pt-BR', { compactDisplay: "short", notation: "compact" })}</div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </motion.div>
                        </motion.div>
                    )}

                    {/* ANALYTICS TAB */}
                    {activeTab === "analytics" && (
                        <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className={cn("p-6 space-y-8 w-[320px]", isCollapsed && "pointer-events-none")}>
                            {/* Chart Controls */}
                            <motion.div animate={{ opacity: isCollapsed ? 0 : 1, filter: isCollapsed ? "blur(4px)" : "blur(0px)" }} className="flex bg-white/5 p-1 rounded-lg">
                                <button onClick={() => setChartType("pie")} className={cn("flex-1 py-1.5 text-xs font-medium rounded-md transition-all", chartType === "pie" ? "bg-gold text-midnight shadow-sm" : "text-white/50 hover:text-white")}>Pizza</button>
                                <button onClick={() => setChartType("liquid")} className={cn("flex-1 py-1.5 text-xs font-medium rounded-md transition-all", chartType === "liquid" ? "bg-gold text-midnight shadow-sm" : "text-white/50 hover:text-white")}>Líquido</button>
                            </motion.div>

                            {/* Charts */}
                            <motion.div animate={{ opacity: isCollapsed ? 0 : 1, filter: isCollapsed ? "blur(8px)" : "blur(0px)" }} className="flex flex-col items-center">
                                {chartType === "pie" ? (
                                    <SimplePieChart data={stats.catData} />
                                ) : (
                                    <div className="flex gap-6 items-end h-40">
                                        <div className="flex flex-col items-center gap-2">
                                            <LiquidChart percentage={75} color="#10b981" />
                                            <span className="text-[10px] text-white/40">Metas</span>
                                        </div>
                                        <div className="flex flex-col items-center gap-2">
                                            <LiquidChart percentage={stats.savingsRate} color="#D4AF37" />
                                            <span className="text-[10px] text-white/40">Economia</span>
                                        </div>
                                    </div>
                                )}
                            </motion.div>

                            {/* Categories Stats */}
                            <motion.div animate={{ opacity: isCollapsed ? 0 : 1, filter: isCollapsed ? "blur(6px)" : "blur(0px)" }} className="space-y-3">
                                <h3 className="text-xs font-bold text-white/50 uppercase tracking-wider">Despesas por Categoria</h3>
                                <div className="space-y-2">
                                    {stats.catData.map((cat, i) => (
                                        <div key={i} className="flex items-center justify-between p-2 rounded-lg hover:bg-white/5 transition-colors">
                                            <div className="flex items-center gap-2">
                                                <div className="w-2 h-2 rounded-full" style={{ backgroundColor: cat.color }} />
                                                <span className="text-xs text-white/80">{cat.label}</span>
                                            </div>
                                            <span className="text-xs font-mono text-white/60">R$ {cat.value}</span>
                                        </div>
                                    ))}
                                </div>
                            </motion.div>
                        </motion.div>
                    )}

                    {/* SETTINGS TAB */}
                    {activeTab === "settings" && (
                        <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} className={cn("p-6 space-y-6 w-[320px]", isCollapsed && "pointer-events-none")}>
                            {/* Content fades with blur instead of moving */}
                            <motion.div animate={{ opacity: isCollapsed ? 0 : 1, filter: isCollapsed ? "blur(8px)" : "blur(0px)" }} className="space-y-6">
                                {/* Profile */}
                                <div className="flex items-center gap-4 pb-6 border-b border-white/5">
                                    <div className="w-12 h-12 rounded-full bg-gold flex items-center justify-center text-midnight font-bold text-lg">U</div>
                                    <div>
                                        <div className="text-sm font-medium text-white">Usuário VIP</div>
                                        <div className="text-xs text-white/40">concierge@finance.com</div>
                                    </div>
                                </div>

                                {/* Options */}
                                <div className="space-y-1">
                                    <button className="w-full flex items-center gap-3 p-3 rounded-lg hover:bg-white/5 text-left transition-colors">
                                        <User className="w-4 h-4 text-white/60" />
                                        <span className="text-sm text-white/80">Minha Conta</span>
                                    </button>
                                    <button className="w-full flex items-center gap-3 p-3 rounded-lg hover:bg-white/5 text-left transition-colors">
                                        <Shield className="w-4 h-4 text-white/60" />
                                        <span className="text-sm text-white/80">Segurança & Privacidade</span>
                                    </button>
                                    <button className="w-full flex items-center gap-3 p-3 rounded-lg hover:bg-white/5 text-left transition-colors">
                                        <Wallet className="w-4 h-4 text-white/60" />
                                        <span className="text-sm text-white/80">Moeda (BRL)</span>
                                    </button>
                                    <button className="w-full flex items-center gap-3 p-3 rounded-lg hover:bg-white/5 text-left transition-colors">
                                        <Download className="w-4 h-4 text-white/60" />
                                        <span className="text-sm text-white/80">Exportar Dados (CSV)</span>
                                    </button>
                                </div>

                                {/* Danger Zone */}
                                <div className="pt-4 border-t border-white/5 space-y-1">
                                    <button className="w-full flex items-center gap-3 p-3 rounded-lg hover:bg-rose-500/10 text-left transition-colors group">
                                        <Trash2 className="w-4 h-4 text-rose-500/60 group-hover:text-rose-500" />
                                        <span className="text-sm text-rose-500/80 group-hover:text-rose-500">Resetar Transações</span>
                                    </button>
                                    <button className="w-full flex items-center gap-3 p-3 rounded-lg hover:bg-white/5 text-left transition-colors">
                                        <LogOut className="w-4 h-4 text-white/40" />
                                        <span className="text-sm text-white/60">Sair</span>
                                    </button>
                                </div>
                            </motion.div>
                        </motion.div>
                    )}
                </div>

                {/* --- BOTTOM NAVIGATION TABS --- */}
                <div className="p-2 border-t border-white/5 shrink-0 bg-midnight/90 backdrop-blur-md w-[320px]">
                    <div className="flex items-center px-4 gap-2"> {/* Changed to flex with fixed gap/padding. Fixed icons */}
                        <button
                            onClick={() => setActiveTab("home")}
                            className={cn("flex flex-col items-center justify-center gap-1 w-14 h-14 rounded-lg transition-all shrink-0", activeTab === "home" ? "bg-white/10 text-gold" : "text-white/40 hover:text-white/70")}
                        >
                            <History className="w-5 h-5" />
                            <motion.span animate={{ height: isCollapsed ? 0 : "auto", opacity: isCollapsed ? 0 : 1 }} className="text-[9px] font-medium tracking-wide overflow-hidden">Recentes</motion.span>
                        </button>
                        <button
                            onClick={() => setActiveTab("analytics")}
                            className={cn("flex flex-col items-center justify-center gap-1 w-14 h-14 rounded-lg transition-all shrink-0", activeTab === "analytics" ? "bg-white/10 text-gold" : "text-white/40 hover:text-white/70")}
                        >
                            <BarChart3 className="w-5 h-5" />
                            <motion.span animate={{ height: isCollapsed ? 0 : "auto", opacity: isCollapsed ? 0 : 1 }} className="text-[9px] font-medium tracking-wide overflow-hidden">Análise</motion.span>
                        </button>
                        <button
                            onClick={() => setActiveTab("settings")}
                            className={cn("flex flex-col items-center justify-center gap-1 w-14 h-14 rounded-lg transition-all shrink-0", activeTab === "settings" ? "bg-white/10 text-gold" : "text-white/40 hover:text-white/70")}
                        >
                            <Settings className="w-5 h-5" />
                            <motion.span animate={{ height: isCollapsed ? 0 : "auto", opacity: isCollapsed ? 0 : 1 }} className="text-[9px] font-medium tracking-wide overflow-hidden">Ajustes</motion.span>
                        </button>
                    </div>
                </div>
            </motion.div>
        </>
    );
}
