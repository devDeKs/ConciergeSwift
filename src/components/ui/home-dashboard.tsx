"use client";

import { motion } from "framer-motion";
import { ArrowUpRight, ArrowDownRight, Bell, ShoppingCart, Car, Music, Dumbbell, Wallet, Store, Menu } from "lucide-react";
import { cn } from "@/lib/utils";
import { useTransactions } from "@/hooks/useTransactions";
import { useProfile } from "@/hooks/useProfile";
import { BalanceCard } from "./balance-card";

interface TransactionItemProps {
    description: string;
    category: string;
    amount: number;
    type: "income" | "expense";
    date: string;
    icon?: string;
}

// Duplicate imports removed

// ... existing code ...

function TransactionItem({ description, category, amount, type, date }: TransactionItemProps) {
    const formatAmount = (value: number) => {
        return value.toLocaleString('pt-BR', { minimumFractionDigits: 2 });
    };

    const formatDate = (dateString: string) => {
        const date = new Date(dateString);
        const now = new Date();
        const diff = now.getTime() - date.getTime();
        const days = Math.floor(diff / (1000 * 60 * 60 * 24));

        if (days === 0) return "Hoje";
        if (days === 1) return "Ontem";
        return date.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' });
    };

    // Icon Mapping Logic
    const getIcon = () => {
        const lowerDesc = description.toLowerCase();
        if (lowerDesc.includes('supermercado') || lowerDesc.includes('amazon')) return <ShoppingCart className="w-5 h-5" />;
        if (lowerDesc.includes('uber') || lowerDesc.includes('transporte')) return <Car className="w-5 h-5" />;
        if (lowerDesc.includes('spotify') || lowerDesc.includes('netflix')) return <Music className="w-5 h-5" />;
        if (lowerDesc.includes('smart fit') || lowerDesc.includes('gym')) return <Dumbbell className="w-5 h-5" />;
        if (lowerDesc.includes('salário') || lowerDesc.includes('renda')) return <Wallet className="w-5 h-5" />;
        return <Store className="w-5 h-5" />;
    };

    return (
        <motion.div
            initial={{ opacity: 0, x: -10 }}
            animate={{ opacity: 1, x: 0 }}
            className="flex items-center gap-4 p-4 hover:bg-gray-50 active:bg-gray-100 transition-colors rounded-2xl group"
        >
            {/* Icon Container - Premium Look */}
            <div className={cn(
                "w-12 h-12 rounded-full flex items-center justify-center transition-colors shadow-sm",
                type === "income"
                    ? "bg-emerald-100 text-emerald-600"
                    : "bg-midnight text-gold" // Dark background with gold icon for expenses
            )}>
                {getIcon()}
            </div>

            {/* Details */}
            <div className="flex-1 min-w-0">
                <div className="font-semibold text-gray-900 truncate text-[15px]">{description}</div>
                <div className="text-sm text-gray-400 font-medium">{category}</div>
            </div>

            {/* Amount & Date */}
            <div className="text-right">
                <div className={cn(
                    "font-medium text-[16px] tracking-normal",
                    type === "income" ? "text-emerald-600" : "text-gray-900"
                )}>
                    {type === "income" ? "+" : "-"} R$ {formatAmount(amount)}
                </div>
                <div className="text-xs text-gray-400 font-medium mt-0.5">
                    {formatDate(date)}
                </div>
            </div>
        </motion.div>
    );
}

interface HomeDashboardProps {
    onNavigateToChat?: () => void;
    onNavigateToCards?: () => void;
    onNavigateToProfile?: () => void;
}

export function HomeDashboard({
    onNavigateToChat,
    onNavigateToCards,
    onNavigateToProfile,
}: HomeDashboardProps) {
    const { transactions, summary, loading } = useTransactions();
    const { profile } = useProfile();

    const firstName = (profile as { display_name?: string })?.display_name?.split(' ')[0] || 'Usuário';

    return (
        <div className="flex flex-col h-[100dvh] bg-white overflow-hidden">
            {/* Dark Header Section - Rounded bottom */}
            <div className="relative bg-gradient-to-b from-midnight to-midnight-light pt-[calc(3rem+env(safe-area-inset-top))] pb-24 rounded-b-[3.5rem] shrink-0">
                {/* Header */}
                <div className="flex items-center justify-between px-6 mb-6 relative">
                    {/* Menu Icon (Left) */}
                    <button className="w-10 h-10 rounded-full flex items-center justify-center text-gold/80 hover:bg-white/10 transition-colors">
                        <Menu className="w-6 h-6" />
                    </button>

                    {/* Logo (Center) - Solid Gold */}
                    <h1
                        className="text-[32px] font-serif tracking-wide text-gold drop-shadow-sm"
                        style={{ fontFamily: 'var(--font-playfair)' }}
                    >
                        Concierge
                    </h1>

                    {/* Notification Icon (Right) */}
                    <button
                        className="w-10 h-10 rounded-full bg-white/10 border border-white/20 flex items-center justify-center text-white/80 hover:bg-white/20 transition-colors relative"
                    >
                        <Bell className="w-5 h-5" />
                        {/* Notification dot */}
                        <span className="absolute top-2 right-2.5 w-2 h-2 bg-red-500 rounded-full border border-midnight" />
                    </button>
                </div>
            </div>

            {/* Balance Card - Positioned to overlap both sections */}
            <div className="relative z-10 -mt-20 px-4">
                <BalanceCard
                    balance={summary?.balance || 0}
                    income={summary?.income || 0}
                    expenses={summary?.expenses || 0}
                    onSend={onNavigateToChat}
                    onReceive={onNavigateToChat}
                    onCards={onNavigateToCards}
                    onMore={() => { }}
                />
            </div>

            {/* Light Transaction Section */}
            <div className="flex-1 bg-white overflow-y-auto overflow-x-hidden pb-[calc(6rem+env(safe-area-inset-bottom))]">
                <div className="p-5 pt-6">
                    {/* Section Header */}
                    <div className="flex items-center justify-between mb-4">
                        <h2 className="text-lg font-semibold text-gray-900">Transações</h2>
                        <button className="text-sm text-gold font-medium hover:underline">
                            Ver todas
                        </button>
                    </div>

                    {/* Transaction List */}
                    <div className="space-y-1">
                        {loading ? (
                            <div className="flex items-center justify-center py-8">
                                <div className="w-6 h-6 border-2 border-gold border-t-transparent rounded-full animate-spin" />
                            </div>
                        ) : (
                            // Use mock transactions combined with real ones or just overrides for testing as requested
                            [
                                { id: '1', description: 'Supermercado', category: 'Alimentação', amount: 450.00, type: 'expense', created_at: new Date().toISOString() },
                                { id: '2', description: 'Salário Mensal', category: 'Renda', amount: 4500.00, type: 'income', created_at: new Date(Date.now() - 86400000).toISOString() },
                                { id: '3', description: 'Uber Trip', category: 'Transporte', amount: 24.90, type: 'expense', created_at: new Date(Date.now() - 86400000 * 2).toISOString() },
                                { id: '4', description: 'Spotify Premium', category: 'Lazer', amount: 21.90, type: 'expense', created_at: new Date(Date.now() - 86400000 * 3).toISOString() },
                                { id: '5', description: 'Smart Fit', category: 'Saúde', amount: 119.90, type: 'expense', created_at: new Date(Date.now() - 86400000 * 5).toISOString() },
                                ...transactions
                            ].map((transaction, idx) => (
                                <TransactionItem
                                    key={idx}
                                    description={transaction.description}
                                    category={transaction.category}
                                    amount={Number(transaction.amount)}
                                    type={transaction.type as "income" | "expense"}
                                    date={transaction.created_at}
                                />
                            ))
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
