"use client"

import { motion, AnimatePresence } from "framer-motion"
import { cn } from "@/lib/utils"
import { useFreeBalance } from "@/hooks/useFreeBalance"
import { useAuth } from "@/contexts/AuthContext"
import {
    ChevronDown,
    ChevronUp,
    Receipt,
    CreditCard,
    Target,
    Wallet,
    TrendingUp,
    AlertCircle
} from "lucide-react"
import { useState } from "react"

// Status color configurations
const statusColors = {
    green: {
        bg: "from-emerald-500/20 to-emerald-600/10",
        border: "border-emerald-500/30",
        glow: "shadow-[0_0_40px_-10px_rgba(16,185,129,0.6)]",
        pulse: "bg-emerald-500",
        text: "text-emerald-400",
        icon: "text-emerald-400"
    },
    yellow: {
        bg: "from-amber-500/20 to-amber-600/10",
        border: "border-amber-500/30",
        glow: "shadow-[0_0_40px_-10px_rgba(245,158,11,0.6)]",
        pulse: "bg-amber-500",
        text: "text-amber-400",
        icon: "text-amber-400"
    },
    red: {
        bg: "from-rose-500/20 to-rose-600/10",
        border: "border-rose-500/30",
        glow: "shadow-[0_0_40px_-10px_rgba(244,63,94,0.6)]",
        pulse: "bg-rose-500",
        text: "text-rose-400",
        icon: "text-rose-400"
    }
}

// Format currency
const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL'
    }).format(value)
}

interface FreeBalanceIndicatorProps {
    className?: string
    compact?: boolean
}

export function FreeBalanceIndicator({ className, compact = false }: FreeBalanceIndicatorProps) {
    const { user } = useAuth()
    const { data, loading, error } = useFreeBalance()
    const [isExpanded, setIsExpanded] = useState(false)

    // Don't render if not logged in
    if (!user) return null

    // Loading state
    if (loading) {
        return (
            <motion.div
                className={cn(
                    "backdrop-blur-xl bg-midnight-light/30 rounded-2xl border border-white/10 p-4",
                    className
                )}
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
            >
                <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-full bg-white/5 animate-pulse" />
                    <div className="space-y-2">
                        <div className="h-4 w-24 bg-white/5 rounded animate-pulse" />
                        <div className="h-6 w-32 bg-white/5 rounded animate-pulse" />
                    </div>
                </div>
            </motion.div>
        )
    }

    // Error state
    if (error || !data) {
        return (
            <motion.div
                className={cn(
                    "backdrop-blur-xl bg-midnight-light/30 rounded-2xl border border-rose-500/20 p-4",
                    className
                )}
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
            >
                <div className="flex items-center gap-3 text-rose-400">
                    <AlertCircle className="w-5 h-5" />
                    <span className="text-sm">Erro ao carregar saldo</span>
                </div>
            </motion.div>
        )
    }

    const colors = statusColors[data.status]

    // Compact mode - toggles between pill and expanded
    if (compact) {
        return (
            <AnimatePresence mode="wait">
                {!isExpanded ? (
                    // Compact pill view
                    <motion.button
                        key="compact"
                        onClick={() => setIsExpanded(true)}
                        className={cn(
                            "relative flex items-center gap-2 backdrop-blur-xl bg-midnight-light/30 rounded-full",
                            "border px-4 py-2.5 transition-all duration-300 hover:scale-105",
                            colors.border,
                            colors.glow,
                            className
                        )}
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                        exit={{ opacity: 0, scale: 0.8 }}
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.98 }}
                    >
                        {/* Pulsing status dot */}
                        <div className="relative">
                            <div className={cn("w-3 h-3 rounded-full", colors.pulse)} />
                            <div className={cn("absolute inset-0 w-3 h-3 rounded-full animate-ping opacity-75", colors.pulse)} />
                        </div>
                        <span className={cn("text-sm font-medium", colors.text)}>
                            {formatCurrency(data.freeBalance)}
                        </span>
                        <span className="text-white/40 text-xs">•</span>
                        <span className={cn("text-xs", colors.text)}>{data.statusLabel}</span>
                        <ChevronDown className="w-3 h-3 text-white/40 ml-1" />
                    </motion.button>
                ) : (
                    // Expanded full view
                    <motion.div
                        key="expanded"
                        className={cn(
                            "backdrop-blur-xl rounded-2xl border overflow-hidden w-full max-w-sm",
                            "bg-gradient-to-br",
                            colors.bg,
                            colors.border,
                            colors.glow
                        )}
                        initial={{ opacity: 0, scale: 0.9, y: -10 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.9, y: -10 }}
                        transition={{ duration: 0.3, ease: [0.32, 0.72, 0, 1] }}
                    >
                        {/* Header with collapse button */}
                        <div className="p-4 flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                {/* Status Circle */}
                                <div className="relative">
                                    <motion.div
                                        className={cn("w-10 h-10 rounded-full flex items-center justify-center bg-gradient-to-br from-white/10 to-transparent border", colors.border)}
                                        animate={{ boxShadow: [`0 0 15px -5px ${data.status === 'green' ? 'rgba(16,185,129,0.5)' : data.status === 'yellow' ? 'rgba(245,158,11,0.5)' : 'rgba(244,63,94,0.5)'}`] }}
                                    >
                                        <motion.div
                                            className={cn("w-5 h-5 rounded-full", colors.pulse)}
                                            animate={{ scale: [1, 1.1, 1], opacity: [0.8, 1, 0.8] }}
                                            transition={{ duration: 1.5, repeat: Infinity }}
                                        />
                                    </motion.div>
                                </div>
                                <div>
                                    <p className="text-white/50 text-xs">Saldo Livre</p>
                                    <p className={cn("text-lg font-light", colors.text)}>
                                        {formatCurrency(data.freeBalance)}
                                    </p>
                                </div>
                            </div>
                            <button
                                onClick={() => setIsExpanded(false)}
                                className="p-2 rounded-full bg-white/5 hover:bg-white/10 transition-colors"
                            >
                                <ChevronUp className="w-4 h-4 text-white/60" />
                            </button>
                        </div>

                        {/* Breakdown */}
                        <div className="px-4 pb-4 border-t border-white/5 pt-3 space-y-2.5">
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                    <Wallet className="w-3.5 h-3.5 text-gold/70" />
                                    <span className="text-xs text-white/70">Saldo Atual</span>
                                </div>
                                <span className="text-xs font-medium text-white/90">{formatCurrency(data.currentBalance)}</span>
                            </div>
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                    <Receipt className="w-3.5 h-3.5 text-rose-400/70" />
                                    <span className="text-xs text-white/70">Contas ({data.billsCount})</span>
                                </div>
                                <span className="text-xs font-medium text-rose-400/90">- {formatCurrency(data.pendingBills)}</span>
                            </div>
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                    <CreditCard className="w-3.5 h-3.5 text-amber-400/70" />
                                    <span className="text-xs text-white/70">Fatura Cartão</span>
                                </div>
                                <span className="text-xs font-medium text-amber-400/90">- {formatCurrency(data.creditCardInvoice)}</span>
                            </div>
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                    <Target className="w-3.5 h-3.5 text-blue-400/70" />
                                    <span className="text-xs text-white/70">Reserva Metas ({data.goalsCount})</span>
                                </div>
                                <span className="text-xs font-medium text-blue-400/90">- {formatCurrency(data.goalsReserve)}</span>
                            </div>
                            <div className="border-t border-white/10 pt-2 mt-2">
                                <div className="flex items-center justify-between">
                                    <span className="text-xs font-medium text-white/80">= Saldo Livre</span>
                                    <span className={cn("text-sm font-semibold", colors.text)}>{formatCurrency(data.freeBalance)}</span>
                                </div>
                            </div>
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        )
    }

    // Full mode
    return (
        <motion.div
            className={cn(
                "backdrop-blur-xl rounded-2xl border overflow-hidden",
                "bg-gradient-to-br",
                colors.bg,
                colors.border,
                colors.glow,
                "transition-all duration-500",
                className
            )}
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ duration: 0.5, ease: [0.32, 0.72, 0, 1] }}
        >
            {/* Main Content */}
            <div className="p-5">
                <div className="flex items-start justify-between gap-4">
                    {/* Left: Status Circle + Info */}
                    <div className="flex items-center gap-4">
                        {/* Animated Status Circle */}
                        <div className="relative">
                            <motion.div
                                className={cn(
                                    "w-16 h-16 rounded-full flex items-center justify-center",
                                    "bg-gradient-to-br from-white/10 to-transparent",
                                    "border-2",
                                    colors.border
                                )}
                                animate={{
                                    boxShadow: [
                                        `0 0 20px -5px ${data.status === 'green' ? 'rgba(16,185,129,0.4)' : data.status === 'yellow' ? 'rgba(245,158,11,0.4)' : 'rgba(244,63,94,0.4)'}`,
                                        `0 0 40px -5px ${data.status === 'green' ? 'rgba(16,185,129,0.6)' : data.status === 'yellow' ? 'rgba(245,158,11,0.6)' : 'rgba(244,63,94,0.6)'}`,
                                        `0 0 20px -5px ${data.status === 'green' ? 'rgba(16,185,129,0.4)' : data.status === 'yellow' ? 'rgba(245,158,11,0.4)' : 'rgba(244,63,94,0.4)'}`
                                    ]
                                }}
                                transition={{
                                    duration: 2,
                                    repeat: Infinity,
                                    ease: "easeInOut"
                                }}
                            >
                                {/* Inner pulsing core */}
                                <div className="relative">
                                    <motion.div
                                        className={cn("w-8 h-8 rounded-full", colors.pulse)}
                                        animate={{
                                            scale: [1, 1.1, 1],
                                            opacity: [0.8, 1, 0.8]
                                        }}
                                        transition={{
                                            duration: 1.5,
                                            repeat: Infinity,
                                            ease: "easeInOut"
                                        }}
                                    />
                                    <motion.div
                                        className={cn("absolute inset-0 w-8 h-8 rounded-full", colors.pulse)}
                                        animate={{
                                            scale: [1, 1.5],
                                            opacity: [0.5, 0]
                                        }}
                                        transition={{
                                            duration: 1.5,
                                            repeat: Infinity,
                                            ease: "easeOut"
                                        }}
                                    />
                                </div>
                            </motion.div>
                        </div>

                        {/* Text Info */}
                        <div className="space-y-1">
                            <p className="text-white/50 text-sm font-light">Saldo Livre</p>
                            <p className={cn("text-2xl font-light tracking-tight", colors.text)}>
                                {formatCurrency(data.freeBalance)}
                            </p>
                            <div className="flex items-center gap-1.5">
                                <TrendingUp className={cn("w-3 h-3", colors.icon)} />
                                <span className={cn("text-xs font-medium", colors.text)}>
                                    {data.statusLabel}
                                </span>
                            </div>
                        </div>
                    </div>

                    {/* Expand/Collapse Button */}
                    <motion.button
                        onClick={() => setIsExpanded(!isExpanded)}
                        className={cn(
                            "p-2 rounded-full bg-white/5 hover:bg-white/10",
                            "transition-colors duration-200"
                        )}
                        whileTap={{ scale: 0.9 }}
                    >
                        {isExpanded ? (
                            <ChevronUp className="w-4 h-4 text-white/60" />
                        ) : (
                            <ChevronDown className="w-4 h-4 text-white/60" />
                        )}
                    </motion.button>
                </div>
            </div>

            {/* Expandable Breakdown */}
            <AnimatePresence>
                {isExpanded && (
                    <motion.div
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: "auto", opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        transition={{ duration: 0.3, ease: [0.32, 0.72, 0, 1] }}
                        className="overflow-hidden"
                    >
                        <div className="px-5 pb-5 pt-2 border-t border-white/5 space-y-3">
                            {/* Current Balance */}
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                    <Wallet className="w-4 h-4 text-gold/70" />
                                    <span className="text-sm text-white/70">Saldo Atual</span>
                                </div>
                                <span className="text-sm font-medium text-white/90">
                                    {formatCurrency(data.currentBalance)}
                                </span>
                            </div>

                            {/* Pending Bills */}
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                    <Receipt className="w-4 h-4 text-rose-400/70" />
                                    <span className="text-sm text-white/70">
                                        Contas ({data.billsCount})
                                    </span>
                                </div>
                                <span className="text-sm font-medium text-rose-400/90">
                                    - {formatCurrency(data.pendingBills)}
                                </span>
                            </div>

                            {/* Credit Card */}
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                    <CreditCard className="w-4 h-4 text-amber-400/70" />
                                    <span className="text-sm text-white/70">Fatura Cartão</span>
                                </div>
                                <span className="text-sm font-medium text-amber-400/90">
                                    - {formatCurrency(data.creditCardInvoice)}
                                </span>
                            </div>

                            {/* Goals Reserve */}
                            <div className="flex items-center justify-between">
                                <div className="flex items-center gap-2">
                                    <Target className="w-4 h-4 text-blue-400/70" />
                                    <span className="text-sm text-white/70">
                                        Reserva Metas ({data.goalsCount})
                                    </span>
                                </div>
                                <span className="text-sm font-medium text-blue-400/90">
                                    - {formatCurrency(data.goalsReserve)}
                                </span>
                            </div>

                            {/* Divider */}
                            <div className="border-t border-white/10 pt-3">
                                <div className="flex items-center justify-between">
                                    <span className="text-sm font-medium text-white/80">
                                        = Saldo Livre
                                    </span>
                                    <span className={cn("text-lg font-semibold", colors.text)}>
                                        {formatCurrency(data.freeBalance)}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </motion.div>
    )
}
