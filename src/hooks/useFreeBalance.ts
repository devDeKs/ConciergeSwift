"use client"

import { useState, useEffect, useCallback } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { useTransactions } from './useTransactions'
import {
    FreeBalanceData,
    calculateFreeBalance,
    getScheduledBills,
    getCreditCards,
    getSavingsGoals,
    ScheduledBill,
    CreditCard,
    SavingsGoal
} from '@/lib/freeBalance'

interface UseFreeBalanceReturn {
    data: FreeBalanceData | null
    bills: ScheduledBill[]
    creditCards: CreditCard[]
    goals: SavingsGoal[]
    loading: boolean
    error: string | null
    refresh: () => Promise<void>
}

export function useFreeBalance(): UseFreeBalanceReturn {
    const { user } = useAuth()
    const { summary } = useTransactions()
    const [data, setData] = useState<FreeBalanceData | null>(null)
    const [bills, setBills] = useState<ScheduledBill[]>([])
    const [creditCards, setCreditCards] = useState<CreditCard[]>([])
    const [goals, setGoals] = useState<SavingsGoal[]>([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    const loadData = useCallback(async () => {
        if (!user) {
            setData(null)
            setBills([])
            setCreditCards([])
            setGoals([])
            setLoading(false)
            return
        }

        setLoading(true)
        setError(null)

        try {
            // Get current balance from transactions summary
            const currentBalance = summary?.balance || 0

            // Fetch all related data
            const [billsResult, cardsResult, goalsResult] = await Promise.all([
                getScheduledBills(),
                getCreditCards(),
                getSavingsGoals()
            ])

            setBills(billsResult.data || [])
            setCreditCards(cardsResult.data || [])
            setGoals(goalsResult.data || [])

            // Calculate free balance
            const freeBalanceData = await calculateFreeBalance(currentBalance)
            setData(freeBalanceData)
        } catch (err) {
            console.error('Error loading free balance data:', err)
            setError('Erro ao calcular saldo livre')
        } finally {
            setLoading(false)
        }
    }, [user, summary])

    // Load data when user or summary changes
    useEffect(() => {
        loadData()
    }, [loadData])

    return {
        data,
        bills,
        creditCards,
        goals,
        loading,
        error,
        refresh: loadData
    }
}
