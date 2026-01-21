"use client";

import { motion, AnimatePresence } from "framer-motion";
import { CreditCard, Plus, Calendar, ChevronRight, Loader2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { useState } from "react";
import { InstallmentModal } from "./installment-modal";

interface CardInstallment {
    id: string;
    description: string;
    totalAmount: number;
    installmentAmount: number;
    currentInstallment: number;
    totalInstallments: number;
    dueDate: string;
    cardName: string;
}

// Mock data - will be replaced with real data
const mockInstallments: CardInstallment[] = [
    {
        id: "1",
        description: "iPhone 15 Pro",
        totalAmount: 8999,
        installmentAmount: 749.92,
        currentInstallment: 3,
        totalInstallments: 12,
        dueDate: "2024-02-10",
        cardName: "Nubank",
    },
    {
        id: "2",
        description: "TV Samsung 55\"",
        totalAmount: 3500,
        installmentAmount: 350,
        currentInstallment: 5,
        totalInstallments: 10,
        dueDate: "2024-02-15",
        cardName: "Itaú",
    },
];

function InstallmentCard({ installment }: { installment: CardInstallment }) {
    const formatCurrency = (value: number) => {
        return value.toLocaleString('pt-BR', { minimumFractionDigits: 2 });
    };

    const progress = (installment.currentInstallment / installment.totalInstallments) * 100;

    return (
        <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            className="p-4 bg-white rounded-xl border border-gray-100 shadow-sm"
        >
            <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-midnight/5 flex items-center justify-center">
                        <CreditCard className="w-5 h-5 text-midnight" />
                    </div>
                    <div>
                        <div className="font-medium text-gray-900">{installment.description}</div>
                        <div className="text-xs text-gray-500">{installment.cardName}</div>
                    </div>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-300" />
            </div>

            {/* Progress bar */}
            <div className="mb-3">
                <div className="flex items-center justify-between text-xs mb-1">
                    <span className="text-gray-500">
                        {installment.currentInstallment} de {installment.totalInstallments} parcelas
                    </span>
                    <span className="text-gold font-medium">{Math.round(progress)}%</span>
                </div>
                <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <motion.div
                        initial={{ width: 0 }}
                        animate={{ width: `${progress}%` }}
                        transition={{ duration: 0.5, ease: "easeOut" }}
                        className="h-full bg-gradient-to-r from-gold to-gold-light rounded-full"
                    />
                </div>
            </div>

            {/* Amount info */}
            <div className="flex items-center justify-between text-sm">
                <div className="text-gray-500">
                    <span>Próxima parcela:</span>
                </div>
                <div className="font-semibold text-gray-900">
                    R$ {formatCurrency(installment.installmentAmount)}
                </div>
            </div>
        </motion.div>
    );
}

export function CardsTab() {
    const [showModal, setShowModal] = useState(false);
    const [installments] = useState<CardInstallment[]>(mockInstallments);
    const [loading] = useState(false);

    const totalMonthly = installments.reduce((acc, i) => acc + i.installmentAmount, 0);

    return (
        <div className="flex flex-col h-full bg-background">
            {/* Dark Header Section */}
            <div className="bg-gradient-to-b from-midnight to-midnight-light pt-12 pb-8 px-5">
                <h1
                    className="text-xl font-serif text-white tracking-wide text-center mb-6"
                    style={{ fontFamily: 'var(--font-playfair)' }}
                >
                    Cartões
                </h1>

                {/* Monthly Total Card */}
                <motion.div
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="bg-white/5 border border-white/10 rounded-2xl p-4"
                >
                    <div className="text-white/50 text-sm mb-1">Total em parcelas este mês</div>
                    <div className="text-2xl font-bold text-white">
                        R$ {totalMonthly.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
                    </div>
                    <div className="text-xs text-white/40 mt-1">
                        {installments.length} parcelamento{installments.length !== 1 ? 's' : ''} ativo{installments.length !== 1 ? 's' : ''}
                    </div>
                </motion.div>
            </div>

            {/* Light Content Section */}
            <div className="flex-1 bg-white rounded-t-3xl -mt-4 overflow-auto">
                <div className="p-5">
                    {/* Header */}
                    <div className="flex items-center justify-between mb-4">
                        <h2 className="text-lg font-semibold text-gray-900">Parcelamentos</h2>
                        <button
                            onClick={() => setShowModal(true)}
                            className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-gold/10 text-gold text-sm font-medium hover:bg-gold/20 transition-colors"
                        >
                            <Plus className="w-4 h-4" />
                            Novo
                        </button>
                    </div>

                    {/* Installments List */}
                    <div className="space-y-3">
                        {loading ? (
                            <div className="flex items-center justify-center py-8">
                                <Loader2 className="w-6 h-6 text-gold animate-spin" />
                            </div>
                        ) : installments.length === 0 ? (
                            <div className="flex flex-col items-center justify-center py-12 text-center">
                                <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mb-4">
                                    <CreditCard className="w-6 h-6 text-gray-400" />
                                </div>
                                <p className="text-gray-500 mb-1">Nenhum parcelamento</p>
                                <p className="text-sm text-gray-400">Adicione suas compras parceladas</p>
                            </div>
                        ) : (
                            installments.map((installment) => (
                                <InstallmentCard key={installment.id} installment={installment} />
                            ))
                        )}
                    </div>
                </div>
            </div>

            {/* Installment Modal */}
            <InstallmentModal
                isOpen={showModal}
                onClose={() => setShowModal(false)}
                onConfirm={(data) => {
                    console.log('New installment:', data);
                    setShowModal(false);
                }}
            />
        </div>
    );
}
