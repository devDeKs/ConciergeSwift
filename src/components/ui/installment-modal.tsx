"use client"

import { useState, useMemo } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { cn } from "@/lib/utils"
import { useAuth } from "@/contexts/AuthContext"
import {
    X,
    CreditCard,
    Receipt,
    Smartphone,
    Calendar,
    DollarSign,
    Hash,
    ChevronDown,
    ChevronUp,
    ShoppingBag,
    CheckCircle2
} from "lucide-react"
import { InstallmentEngine, InstallmentInput, InstallmentOutput, PaymentMethod } from "@/lib/installmentEngine"

// Format currency
const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL'
    }).format(value)
}

// Format date for display
const formatDateDisplay = (dateStr: string) => {
    const [year, month, day] = dateStr.split('-')
    return `${day}/${month}/${year}`
}

interface InstallmentModalProps {
    isOpen: boolean
    onClose: () => void
    onConfirm?: (installments: InstallmentOutput[]) => void
}

export function InstallmentModal({ isOpen, onClose, onConfirm }: InstallmentModalProps) {
    const { user } = useAuth()
    const [totalAmount, setTotalAmount] = useState<string>("")
    const [numberOfInstallments, setNumberOfInstallments] = useState<number>(2)
    const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("credit_card")
    const [description, setDescription] = useState<string>("")
    const [category, setCategory] = useState<string>("Compras")
    const [creditCardClosingDay, setCreditCardClosingDay] = useState<number>(5)
    const [creditCardDueDay, setCreditCardDueDay] = useState<number>(15)
    const [showPreview, setShowPreview] = useState<boolean>(false)
    const [isSubmitting, setIsSubmitting] = useState<boolean>(false)
    const [submitSuccess, setSubmitSuccess] = useState<boolean>(false)

    const engine = useMemo(() => new InstallmentEngine(), [])

    // Parse amount input
    const parsedAmount = useMemo(() => {
        const cleaned = totalAmount.replace(/[^\d,]/g, '').replace(',', '.')
        return parseFloat(cleaned) || 0
    }, [totalAmount])

    // Calculate installments preview
    const installmentsPreview = useMemo(() => {
        if (parsedAmount <= 0 || !description.trim()) return null

        try {
            const input: InstallmentInput = {
                totalAmount: parsedAmount,
                numberOfInstallments,
                startDate: new Date(),
                paymentMethod,
                creditCardClosingDay: paymentMethod === 'credit_card' ? creditCardClosingDay : undefined,
                creditCardDueDay: paymentMethod === 'credit_card' ? creditCardDueDay : undefined,
                description: description.trim(),
                category
            }
            return engine.generateInstallments(input)
        } catch {
            return null
        }
    }, [parsedAmount, numberOfInstallments, paymentMethod, description, category, creditCardClosingDay, creditCardDueDay, engine])

    const handleSubmit = async () => {
        if (!installmentsPreview || !user) return

        setIsSubmitting(true)
        try {
            onConfirm?.(installmentsPreview)
            setSubmitSuccess(true)
            setTimeout(() => {
                onClose()
                // Reset form
                setTotalAmount("")
                setNumberOfInstallments(2)
                setDescription("")
                setShowPreview(false)
                setSubmitSuccess(false)
            }, 1500)
        } catch (error) {
            console.error('Error creating installments:', error)
        } finally {
            setIsSubmitting(false)
        }
    }

    const categories = [
        "Compras", "Eletrônicos", "Eletrodomésticos", "Móveis",
        "Viagem", "Saúde", "Educação", "Outros"
    ]

    const paymentMethods: { value: PaymentMethod; label: string; icon: React.ReactNode }[] = [
        { value: 'credit_card', label: 'Cartão', icon: <CreditCard className="w-4 h-4" /> },
        { value: 'boleto', label: 'Boleto', icon: <Receipt className="w-4 h-4" /> },
        { value: 'pix', label: 'PIX', icon: <Smartphone className="w-4 h-4" /> },
    ]

    return (
        <AnimatePresence>
            {isOpen && (
                <>
                    {/* Backdrop */}
                    <motion.div
                        className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        onClick={onClose}
                    />

                    {/* Modal */}
                    <motion.div
                        className={cn(
                            "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50",
                            "w-full max-w-lg max-h-[90vh] overflow-y-auto",
                            "backdrop-blur-2xl bg-midnight/95 rounded-3xl",
                            "border border-white/10 shadow-2xl",
                            "scrollbar-none"
                        )}
                        initial={{ opacity: 0, scale: 0.95, y: 20 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95, y: 20 }}
                        transition={{ duration: 0.3, ease: [0.32, 0.72, 0, 1] }}
                    >
                        {/* Header */}
                        <div className="sticky top-0 bg-midnight/80 backdrop-blur-xl border-b border-white/5 px-6 py-4 flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="p-2 rounded-xl bg-gold/10">
                                    <ShoppingBag className="w-5 h-5 text-gold" />
                                </div>
                                <div>
                                    <h2 className="text-lg font-medium text-white">Criar Parcelamento</h2>
                                    <p className="text-sm text-white/50">Registrar compra parcelada</p>
                                </div>
                            </div>
                            <button
                                onClick={onClose}
                                className="p-2 rounded-xl hover:bg-white/5 transition-colors"
                            >
                                <X className="w-5 h-5 text-white/60" />
                            </button>
                        </div>

                        {/* Content */}
                        <div className="p-6 space-y-6">
                            {/* Amount Input */}
                            <div className="space-y-2">
                                <label className="text-sm text-white/70 flex items-center gap-2">
                                    <DollarSign className="w-4 h-4 text-gold/70" />
                                    Valor Total
                                </label>
                                <div className="relative">
                                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-white/40">R$</span>
                                    <input
                                        type="text"
                                        value={totalAmount}
                                        onChange={(e) => setTotalAmount(e.target.value)}
                                        placeholder="0,00"
                                        className={cn(
                                            "w-full pl-12 pr-4 py-3 rounded-xl",
                                            "bg-midnight-light/50 border border-white/10",
                                            "text-white text-lg font-light",
                                            "placeholder:text-white/30",
                                            "focus:outline-none focus:border-gold/50",
                                            "transition-colors"
                                        )}
                                    />
                                </div>
                            </div>

                            {/* Description */}
                            <div className="space-y-2">
                                <label className="text-sm text-white/70 flex items-center gap-2">
                                    <ShoppingBag className="w-4 h-4 text-gold/70" />
                                    Descrição
                                </label>
                                <input
                                    type="text"
                                    value={description}
                                    onChange={(e) => setDescription(e.target.value)}
                                    placeholder="Ex: iPhone 15, Geladeira..."
                                    className={cn(
                                        "w-full px-4 py-3 rounded-xl",
                                        "bg-midnight-light/50 border border-white/10",
                                        "text-white",
                                        "placeholder:text-white/30",
                                        "focus:outline-none focus:border-gold/50",
                                        "transition-colors"
                                    )}
                                />
                            </div>

                            {/* Number of Installments */}
                            <div className="space-y-2">
                                <label className="text-sm text-white/70 flex items-center gap-2">
                                    <Hash className="w-4 h-4 text-gold/70" />
                                    Número de Parcelas
                                </label>
                                <div className="flex items-center gap-2">
                                    <input
                                        type="range"
                                        min={1}
                                        max={24}
                                        value={numberOfInstallments}
                                        onChange={(e) => setNumberOfInstallments(parseInt(e.target.value))}
                                        className="flex-1 accent-gold"
                                    />
                                    <span className="w-12 text-center text-lg font-medium text-gold">
                                        {numberOfInstallments}x
                                    </span>
                                </div>
                                {parsedAmount > 0 && (
                                    <p className="text-sm text-white/50 text-center">
                                        {formatCurrency(parsedAmount / numberOfInstallments)} por parcela
                                    </p>
                                )}
                            </div>

                            {/* Payment Method */}
                            <div className="space-y-2">
                                <label className="text-sm text-white/70 flex items-center gap-2">
                                    <CreditCard className="w-4 h-4 text-gold/70" />
                                    Forma de Pagamento
                                </label>
                                <div className="grid grid-cols-3 gap-2">
                                    {paymentMethods.map((method) => (
                                        <button
                                            key={method.value}
                                            onClick={() => setPaymentMethod(method.value)}
                                            className={cn(
                                                "flex items-center justify-center gap-2 py-3 rounded-xl",
                                                "border transition-all",
                                                paymentMethod === method.value
                                                    ? "bg-gold/10 border-gold/50 text-gold"
                                                    : "bg-midnight-light/30 border-white/10 text-white/60 hover:border-white/20"
                                            )}
                                        >
                                            {method.icon}
                                            <span className="text-sm">{method.label}</span>
                                        </button>
                                    ))}
                                </div>
                            </div>

                            {/* Credit Card Settings */}
                            {paymentMethod === 'credit_card' && (
                                <motion.div
                                    initial={{ height: 0, opacity: 0 }}
                                    animate={{ height: "auto", opacity: 1 }}
                                    exit={{ height: 0, opacity: 0 }}
                                    className="space-y-4 pt-2"
                                >
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="space-y-2">
                                            <label className="text-xs text-white/50">Dia do Fechamento</label>
                                            <select
                                                value={creditCardClosingDay}
                                                onChange={(e) => setCreditCardClosingDay(parseInt(e.target.value))}
                                                className="w-full px-3 py-2 rounded-lg bg-midnight-light/50 border border-white/10 text-white text-sm focus:outline-none focus:border-gold/50"
                                            >
                                                {Array.from({ length: 28 }, (_, i) => i + 1).map(day => (
                                                    <option key={day} value={day}>{day}</option>
                                                ))}
                                            </select>
                                        </div>
                                        <div className="space-y-2">
                                            <label className="text-xs text-white/50">Dia do Vencimento</label>
                                            <select
                                                value={creditCardDueDay}
                                                onChange={(e) => setCreditCardDueDay(parseInt(e.target.value))}
                                                className="w-full px-3 py-2 rounded-lg bg-midnight-light/50 border border-white/10 text-white text-sm focus:outline-none focus:border-gold/50"
                                            >
                                                {Array.from({ length: 28 }, (_, i) => i + 1).map(day => (
                                                    <option key={day} value={day}>{day}</option>
                                                ))}
                                            </select>
                                        </div>
                                    </div>
                                </motion.div>
                            )}

                            {/* Category */}
                            <div className="space-y-2">
                                <label className="text-sm text-white/70">Categoria</label>
                                <div className="flex flex-wrap gap-2">
                                    {categories.map((cat) => (
                                        <button
                                            key={cat}
                                            onClick={() => setCategory(cat)}
                                            className={cn(
                                                "px-3 py-1.5 rounded-full text-sm transition-all",
                                                category === cat
                                                    ? "bg-gold/20 text-gold border border-gold/30"
                                                    : "bg-white/5 text-white/60 border border-transparent hover:bg-white/10"
                                            )}
                                        >
                                            {cat}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            {/* Preview Toggle */}
                            {installmentsPreview && (
                                <button
                                    onClick={() => setShowPreview(!showPreview)}
                                    className="w-full flex items-center justify-center gap-2 py-3 text-sm text-gold/80 hover:text-gold transition-colors"
                                >
                                    <Calendar className="w-4 h-4" />
                                    {showPreview ? 'Ocultar' : 'Ver'} cronograma de parcelas
                                    {showPreview ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                                </button>
                            )}

                            {/* Preview List */}
                            <AnimatePresence>
                                {showPreview && installmentsPreview && (
                                    <motion.div
                                        initial={{ height: 0, opacity: 0 }}
                                        animate={{ height: "auto", opacity: 1 }}
                                        exit={{ height: 0, opacity: 0 }}
                                        className="overflow-hidden"
                                    >
                                        <div className="bg-midnight-light/30 rounded-xl border border-white/5 divide-y divide-white/5 max-h-48 overflow-y-auto scrollbar-none">
                                            {installmentsPreview.map((inst) => (
                                                <div
                                                    key={inst.installmentNumber}
                                                    className="flex items-center justify-between px-4 py-3"
                                                >
                                                    <div className="flex items-center gap-3">
                                                        <span className="w-8 h-8 rounded-full bg-gold/10 flex items-center justify-center text-xs text-gold font-medium">
                                                            {inst.installmentNumber}
                                                        </span>
                                                        <div>
                                                            <p className="text-sm text-white/80">{formatDateDisplay(inst.dueDate)}</p>
                                                            <p className="text-xs text-white/40">Parcela {inst.installmentNumber}/{inst.totalInstallments}</p>
                                                        </div>
                                                    </div>
                                                    <span className="text-sm font-medium text-white/90">
                                                        {formatCurrency(inst.amount)}
                                                    </span>
                                                </div>
                                            ))}
                                        </div>
                                    </motion.div>
                                )}
                            </AnimatePresence>
                        </div>

                        {/* Footer */}
                        <div className="sticky bottom-0 bg-midnight/80 backdrop-blur-xl border-t border-white/5 px-6 py-4">
                            {submitSuccess ? (
                                <motion.div
                                    initial={{ opacity: 0, scale: 0.9 }}
                                    animate={{ opacity: 1, scale: 1 }}
                                    className="flex items-center justify-center gap-2 text-emerald-400"
                                >
                                    <CheckCircle2 className="w-5 h-5" />
                                    <span>Parcelamento criado com sucesso!</span>
                                </motion.div>
                            ) : (
                                <button
                                    onClick={handleSubmit}
                                    disabled={!installmentsPreview || isSubmitting}
                                    className={cn(
                                        "w-full py-3 rounded-xl font-medium transition-all",
                                        "flex items-center justify-center gap-2",
                                        installmentsPreview
                                            ? "bg-gold text-midnight hover:bg-gold-light shadow-[0_0_20px_-5px_rgba(212,175,55,0.4)]"
                                            : "bg-white/5 text-white/30 cursor-not-allowed"
                                    )}
                                >
                                    {isSubmitting ? (
                                        <div className="w-5 h-5 border-2 border-midnight/30 border-t-midnight rounded-full animate-spin" />
                                    ) : (
                                        <>
                                            <CheckCircle2 className="w-4 h-4" />
                                            Confirmar Parcelamento
                                        </>
                                    )}
                                </button>
                            )}
                        </div>
                    </motion.div>
                </>
            )}
        </AnimatePresence>
    )
}
