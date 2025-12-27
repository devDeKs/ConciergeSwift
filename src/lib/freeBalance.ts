import { supabase } from './supabase'

// ============================================
// Types
// ============================================

export interface ScheduledBill {
    id: string
    user_id: string
    name: string
    amount: number
    due_day: number
    category: string
    is_recurring: boolean
    is_paid: boolean
    paid_at: string | null
    created_at: string
    updated_at: string
}

export interface CreditCard {
    id: string
    user_id: string
    name: string
    card_limit: number
    current_invoice: number
    closing_day: number
    due_day: number
    created_at: string
    updated_at: string
}

export interface SavingsGoal {
    id: string
    user_id: string
    name: string
    target_amount: number
    current_amount: number
    monthly_reserve: number
    target_date: string | null
    icon: string
    color: string
    is_completed: boolean
    created_at: string
    updated_at: string
}

export interface FreeBalanceData {
    currentBalance: number
    pendingBills: number
    creditCardInvoice: number
    goalsReserve: number
    freeBalance: number
    status: 'green' | 'yellow' | 'red'
    statusLabel: string
    billsCount: number
    goalsCount: number
}

// ============================================
// Scheduled Bills Functions
// ============================================

export const getScheduledBills = async () => {
    const { data, error } = await supabase
        .from('scheduled_bills')
        .select('*')
        .order('due_day', { ascending: true })

    return { data: data as ScheduledBill[] | null, error }
}

export const getPendingBillsForMonth = async () => {
    const { data, error } = await supabase
        .from('scheduled_bills')
        .select('*')
        .eq('is_paid', false)
        .order('due_day', { ascending: true })

    if (error) return { data: null, total: 0, error }

    const total = (data || []).reduce((sum, bill) => sum + Number(bill.amount), 0)
    return { data: data as ScheduledBill[], total, error: null }
}

export const createBill = async (input: Omit<ScheduledBill, 'id' | 'user_id' | 'created_at' | 'updated_at' | 'paid_at'>) => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { data: null, error: new Error('Usuário não autenticado') }

    const { data, error } = await supabase
        .from('scheduled_bills')
        .insert({ ...input, user_id: user.id })
        .select()
        .single()

    return { data: data as ScheduledBill | null, error }
}

export const markBillAsPaid = async (id: string) => {
    const { data, error } = await supabase
        .from('scheduled_bills')
        .update({ is_paid: true, paid_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single()

    return { data: data as ScheduledBill | null, error }
}

// ============================================
// Credit Cards Functions
// ============================================

export const getCreditCards = async () => {
    const { data, error } = await supabase
        .from('credit_cards')
        .select('*')
        .order('name', { ascending: true })

    return { data: data as CreditCard[] | null, error }
}

export const getTotalCreditCardInvoice = async () => {
    const { data, error } = await supabase
        .from('credit_cards')
        .select('current_invoice')

    if (error) return { total: 0, error }

    const total = (data || []).reduce((sum, card) => sum + Number(card.current_invoice), 0)
    return { total, error: null }
}

export const createCreditCard = async (input: Omit<CreditCard, 'id' | 'user_id' | 'created_at' | 'updated_at'>) => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { data: null, error: new Error('Usuário não autenticado') }

    const { data, error } = await supabase
        .from('credit_cards')
        .insert({ ...input, user_id: user.id })
        .select()
        .single()

    return { data: data as CreditCard | null, error }
}

export const updateCreditCardInvoice = async (id: string, current_invoice: number) => {
    const { data, error } = await supabase
        .from('credit_cards')
        .update({ current_invoice, updated_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single()

    return { data: data as CreditCard | null, error }
}

// ============================================
// Savings Goals Functions
// ============================================

export const getSavingsGoals = async () => {
    const { data, error } = await supabase
        .from('savings_goals')
        .select('*')
        .eq('is_completed', false)
        .order('created_at', { ascending: false })

    return { data: data as SavingsGoal[] | null, error }
}

export const getTotalGoalsReserve = async () => {
    const { data, error } = await supabase
        .from('savings_goals')
        .select('monthly_reserve')
        .eq('is_completed', false)

    if (error) return { total: 0, error }

    const total = (data || []).reduce((sum, goal) => sum + Number(goal.monthly_reserve), 0)
    return { total, error: null }
}

export const createGoal = async (input: Omit<SavingsGoal, 'id' | 'user_id' | 'created_at' | 'updated_at' | 'is_completed'>) => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return { data: null, error: new Error('Usuário não autenticado') }

    const { data, error } = await supabase
        .from('savings_goals')
        .insert({ ...input, user_id: user.id })
        .select()
        .single()

    return { data: data as SavingsGoal | null, error }
}

export const addToGoal = async (id: string, amount: number) => {
    const { data: goal } = await supabase
        .from('savings_goals')
        .select('current_amount, target_amount')
        .eq('id', id)
        .single()

    if (!goal) return { data: null, error: new Error('Meta não encontrada') }

    const newAmount = Number(goal.current_amount) + amount
    const isCompleted = newAmount >= Number(goal.target_amount)

    const { data, error } = await supabase
        .from('savings_goals')
        .update({
            current_amount: newAmount,
            is_completed: isCompleted,
            updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .select()
        .single()

    return { data: data as SavingsGoal | null, error }
}

// ============================================
// Free Balance Calculation
// ============================================

export const calculateFreeBalance = async (currentBalance: number): Promise<FreeBalanceData> => {
    // Fetch all data in parallel
    const [billsResult, cardsResult, goalsResult] = await Promise.all([
        getPendingBillsForMonth(),
        getTotalCreditCardInvoice(),
        getTotalGoalsReserve()
    ])

    const pendingBills = billsResult.total
    const creditCardInvoice = cardsResult.total
    const goalsReserve = goalsResult.total
    const billsCount = billsResult.data?.length || 0
    const goalsCount = (await getSavingsGoals()).data?.length || 0

    // Calculate free balance
    const freeBalance = currentBalance - pendingBills - creditCardInvoice - goalsReserve

    // Determine status based on free balance relative to current balance
    let status: 'green' | 'yellow' | 'red'
    let statusLabel: string

    if (currentBalance <= 0) {
        status = 'red'
        statusLabel = 'Saldo Negativo'
    } else {
        const percentage = (freeBalance / currentBalance) * 100

        if (percentage >= 20) {
            status = 'green'
            statusLabel = 'Tranquilo'
        } else if (percentage >= 5) {
            status = 'yellow'
            statusLabel = 'Atenção'
        } else {
            status = 'red'
            statusLabel = 'Cuidado'
        }
    }

    return {
        currentBalance,
        pendingBills,
        creditCardInvoice,
        goalsReserve,
        freeBalance,
        status,
        statusLabel,
        billsCount,
        goalsCount
    }
}
