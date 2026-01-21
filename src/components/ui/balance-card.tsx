"use client";

import { motion } from "framer-motion";
import { ArrowUpRight, ArrowDownRight, CreditCard, MoreHorizontal } from "lucide-react";
import { cn } from "@/lib/utils";

interface BalanceCardProps {
    balance: number;
    income?: number;
    expenses?: number;
    onSend?: () => void;
    onReceive?: () => void;
    onCards?: () => void;
    onMore?: () => void;
}

export function BalanceCard({
    balance,
    income = 0,
    expenses = 0,
    onSend,
    onReceive,
    onCards,
    onMore,
}: BalanceCardProps) {
    const formatCurrency = (value: number) => {
        return value.toLocaleString('pt-BR', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    };

    const quickActions = [
        { icon: ArrowUpRight, label: "Receita", onClick: onReceive },
        { icon: ArrowDownRight, label: "Despesa", onClick: onSend },
        { icon: CreditCard, label: "Cartões", onClick: onCards },
        { icon: MoreHorizontal, label: "Relatórios", onClick: onMore },
    ];

    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: "easeOut" }}
            className="relative mx-4 rounded-2xl overflow-hidden shadow-xl shadow-black/30"
        >
            {/* Gold border glow effect - Fades out at bottom */}
            <div className="absolute inset-0 rounded-2xl bg-gradient-to-b from-gold/40 via-gold/10 to-transparent p-[1px]">
                <div className="w-full h-full rounded-2xl bg-gradient-to-br from-midnight-light via-midnight to-midnight-light" />
            </div>

            {/* Art Deco Geometric Pattern Overlay */}
            <div
                className="absolute inset-0 pointer-events-none"
                style={{
                    maskImage: 'linear-gradient(to bottom, transparent 0%, rgba(0,0,0,0.3) 40%, rgba(0,0,0,0.6) 100%)',
                    WebkitMaskImage: 'linear-gradient(to bottom, transparent 0%, rgba(0,0,0,0.3) 40%, rgba(0,0,0,0.6) 100%)',
                }}
            >
                <svg
                    className="w-full h-full opacity-20"
                    viewBox="0 0 100 100"
                    preserveAspectRatio="xMidYMid slice"
                >
                    <defs>
                        <pattern id="artDecoPattern" x="0" y="0" width="20" height="20" patternUnits="userSpaceOnUse">
                            {/* Vertical lines */}
                            <line x1="10" y1="0" x2="10" y2="20" stroke="#B4975A" strokeWidth="0.3" />
                            {/* Diamond shape */}
                            <path d="M10 2 L18 10 L10 18 L2 10 Z" fill="none" stroke="#B4975A" strokeWidth="0.3" />
                            {/* Inner diamond */}
                            <path d="M10 5 L15 10 L10 15 L5 10 Z" fill="none" stroke="#B4975A" strokeWidth="0.2" />
                            {/* Horizontal connectors */}
                            <line x1="0" y1="10" x2="2" y2="10" stroke="#B4975A" strokeWidth="0.3" />
                            <line x1="18" y1="10" x2="20" y2="10" stroke="#B4975A" strokeWidth="0.3" />
                            {/* Corner accents */}
                            <path d="M0 0 L4 4" stroke="#B4975A" strokeWidth="0.2" />
                            <path d="M20 0 L16 4" stroke="#B4975A" strokeWidth="0.2" />
                            <path d="M0 20 L4 16" stroke="#B4975A" strokeWidth="0.2" />
                            <path d="M20 20 L16 16" stroke="#B4975A" strokeWidth="0.2" />
                        </pattern>
                    </defs>
                    <rect width="100%" height="100%" fill="url(#artDecoPattern)" />
                </svg>
            </div>

            {/* Card content */}
            <div className="relative p-5 space-y-5">
                {/* Header */}
                <div className="flex items-center justify-between">
                    <span className="text-white/50 text-sm font-medium">Disponível</span>
                    <span className="px-2 py-0.5 rounded-full bg-gold/10 border border-gold/20 text-gold text-[10px] font-medium uppercase tracking-wider">
                        Saldo
                    </span>
                </div>

                {/* Balance */}
                <div className="space-y-1">
                    <motion.div
                        className="text-3xl md:text-4xl font-bold text-white tracking-tight"
                        initial={{ opacity: 0, scale: 0.9 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ delay: 0.2, duration: 0.4 }}
                    >
                        R$ {formatCurrency(balance)}
                    </motion.div>

                    {/* Income/Expense indicators */}
                    <div className="flex items-center gap-4 text-xs">
                        <div className="flex items-center gap-1 text-emerald-400">
                            <ArrowUpRight className="w-3 h-3" />
                            <span>+{formatCurrency(income)}</span>
                        </div>
                        <div className="flex items-center gap-1 text-rose-400">
                            <ArrowDownRight className="w-3 h-3" />
                            <span>-{formatCurrency(expenses)}</span>
                        </div>
                    </div>
                </div>

                {/* Quick Actions */}
                <div className="flex items-center justify-between pt-2">
                    {quickActions.map((action, index) => (
                        <motion.button
                            key={action.label}
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: 0.3 + index * 0.1 }}
                            onClick={action.onClick}
                            className={cn(
                                "flex flex-col items-center gap-1.5 p-2 rounded-xl",
                                "hover:bg-white/5 active:bg-white/10 active:scale-95 transition-all",
                                "text-white/70 hover:text-white"
                            )}
                        >
                            <div className="w-10 h-10 rounded-full bg-gold/10 border border-gold/30 flex items-center justify-center">
                                <action.icon className="w-4 h-4 text-gold" />
                            </div>
                            <span className="text-[10px] font-medium">{action.label}</span>
                        </motion.button>
                    ))}
                </div>
            </div>
        </motion.div>
    );
}
