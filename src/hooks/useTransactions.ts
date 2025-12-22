"use client"

import { useState, useEffect, useCallback } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import {
    Transaction,
    CreateTransactionInput,
    getTransactions,
    createTransaction,
    updateTransaction,
    deleteTransaction,
    getFinancialSummary
} from '@/lib/transactions'

interface FinancialSummary {
    income: number
    expenses: number
    balance: number
    byCategory: Record<string, { income: number; expense: number }>
    totalTransactions: number
}

export function useTransactions() {
    const { user } = useAuth()
    const [transactions, setTransactions] = useState<Transaction[]>([])
    const [summary, setSummary] = useState<FinancialSummary | null>(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    // Carregar transações
    const loadTransactions = useCallback(async () => {
        if (!user) {
            setTransactions([])
            setSummary(null)
            setLoading(false)
            return
        }

        setLoading(true)
        setError(null)

        try {
            const [transactionsResult, summaryResult] = await Promise.all([
                getTransactions(),
                getFinancialSummary()
            ])

            if (transactionsResult.error) {
                throw transactionsResult.error
            }

            setTransactions(transactionsResult.data || [])
            setSummary(summaryResult.data)
        } catch (err) {
            console.error('Error loading transactions:', err)
            setError('Erro ao carregar transações')
        } finally {
            setLoading(false)
        }
    }, [user])

    // Carregar ao montar e quando usuário mudar
    useEffect(() => {
        loadTransactions()
    }, [loadTransactions])

    // Adicionar transação
    const addTransaction = async (input: CreateTransactionInput) => {
        try {
            const { data, error } = await createTransaction(input)

            if (error) throw error
            if (data) {
                setTransactions(prev => [data, ...prev])
                // Recarregar resumo
                const { data: newSummary } = await getFinancialSummary()
                setSummary(newSummary)
            }

            return { success: true, data }
        } catch (err) {
            console.error('Error adding transaction:', err)
            return { success: false, error: 'Erro ao adicionar transação' }
        }
    }

    // Atualizar transação
    const editTransaction = async (id: string, input: Partial<CreateTransactionInput>) => {
        try {
            const { data, error } = await updateTransaction(id, input)

            if (error) throw error
            if (data) {
                setTransactions(prev =>
                    prev.map(t => t.id === id ? data : t)
                )
                // Recarregar resumo
                const { data: newSummary } = await getFinancialSummary()
                setSummary(newSummary)
            }

            return { success: true, data }
        } catch (err) {
            console.error('Error updating transaction:', err)
            return { success: false, error: 'Erro ao atualizar transação' }
        }
    }

    // Remover transação
    const removeTransaction = async (id: string) => {
        try {
            const { error } = await deleteTransaction(id)

            if (error) throw error

            setTransactions(prev => prev.filter(t => t.id !== id))
            // Recarregar resumo
            const { data: newSummary } = await getFinancialSummary()
            setSummary(newSummary)

            return { success: true }
        } catch (err) {
            console.error('Error deleting transaction:', err)
            return { success: false, error: 'Erro ao remover transação' }
        }
    }

    return {
        transactions,
        summary,
        loading,
        error,
        addTransaction,
        editTransaction,
        removeTransaction,
        refresh: loadTransactions
    }
}
