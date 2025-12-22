import { supabase } from './supabase'

export interface Transaction {
    id: string
    user_id: string
    description: string
    amount: number
    type: 'income' | 'expense'
    category: string
    created_at: string
    updated_at: string
}

export interface CreateTransactionInput {
    description: string
    amount: number
    type: 'income' | 'expense'
    category: string
}

// Buscar todas as transações do usuário logado
export const getTransactions = async () => {
    const { data, error } = await supabase
        .from('transactions')
        .select('*')
        .order('created_at', { ascending: false })

    return { data: data as Transaction[] | null, error }
}

// Buscar transações por período
export const getTransactionsByPeriod = async (startDate: Date, endDate: Date) => {
    const { data, error } = await supabase
        .from('transactions')
        .select('*')
        .gte('created_at', startDate.toISOString())
        .lte('created_at', endDate.toISOString())
        .order('created_at', { ascending: false })

    return { data: data as Transaction[] | null, error }
}

// Criar nova transação
export const createTransaction = async (input: CreateTransactionInput) => {
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        return { data: null, error: new Error('Usuário não autenticado') }
    }

    const { data, error } = await supabase
        .from('transactions')
        .insert({
            ...input,
            user_id: user.id
        })
        .select()
        .single()

    return { data: data as Transaction | null, error }
}

// Atualizar transação
export const updateTransaction = async (id: string, input: Partial<CreateTransactionInput>) => {
    const { data, error } = await supabase
        .from('transactions')
        .update({
            ...input,
            updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .select()
        .single()

    return { data: data as Transaction | null, error }
}

// Deletar transação
export const deleteTransaction = async (id: string) => {
    const { error } = await supabase
        .from('transactions')
        .delete()
        .eq('id', id)

    return { error }
}

// Obter resumo financeiro
export const getFinancialSummary = async () => {
    const { data: transactions, error } = await getTransactions()

    if (error || !transactions) {
        return { data: null, error }
    }

    const income = transactions
        .filter(t => t.type === 'income')
        .reduce((sum, t) => sum + Number(t.amount), 0)

    const expenses = transactions
        .filter(t => t.type === 'expense')
        .reduce((sum, t) => sum + Number(t.amount), 0)

    const balance = income - expenses

    // Agrupar por categoria
    const byCategory = transactions.reduce((acc, t) => {
        if (!acc[t.category]) {
            acc[t.category] = { income: 0, expense: 0 }
        }
        acc[t.category][t.type] += Number(t.amount)
        return acc
    }, {} as Record<string, { income: number; expense: number }>)

    return {
        data: {
            income,
            expenses,
            balance,
            byCategory,
            totalTransactions: transactions.length
        },
        error: null
    }
}

// Parse de mensagem do chat para criar transação
export const parseTransactionFromMessage = (message: string): CreateTransactionInput | null => {
    // Padrões para despesas: "gastei 30 no ifood", "paguei 100 de luz", "comprei algo por 50"
    const expensePatterns = [
        /gastei\s+(\d+(?:[.,]\d{2})?)\s+(?:no|na|em|de)?\s*(.+)/i,
        /paguei\s+(\d+(?:[.,]\d{2})?)\s+(?:de|do|da)?\s*(.+)/i,
        /comprei\s+(.+)\s+por\s+(\d+(?:[.,]\d{2})?)/i,
        /(?:despesa|gasto)\s+(.+)\s+(\d+(?:[.,]\d{2})?)/i
    ]

    // Padrões para receitas: "recebi 1000 de salário", "ganhei 500", "entrou 200"
    const incomePatterns = [
        /recebi\s+(\d+(?:[.,]\d{2})?)\s+(?:de|do|da)?\s*(.+)/i,
        /ganhei\s+(\d+(?:[.,]\d{2})?)\s+(?:de|do|da|com)?\s*(.+)?/i,
        /entrou\s+(\d+(?:[.,]\d{2})?)\s+(?:de|do|da)?\s*(.+)?/i,
        /(?:receita|renda)\s+(.+)\s+(\d+(?:[.,]\d{2})?)/i
    ]

    // Tentar match de despesa
    for (const pattern of expensePatterns) {
        const match = message.match(pattern)
        if (match) {
            const amount = parseFloat(match[1].replace(',', '.'))
            const description = match[2]?.trim() || 'Despesa'
            const category = categorizeTransaction(description)

            return {
                amount,
                description,
                type: 'expense',
                category
            }
        }
    }

    // Tentar match de receita
    for (const pattern of incomePatterns) {
        const match = message.match(pattern)
        if (match) {
            const amount = parseFloat(match[1].replace(',', '.'))
            const description = match[2]?.trim() || 'Receita'
            const category = categorizeTransaction(description, 'income')

            return {
                amount,
                description,
                type: 'income',
                category
            }
        }
    }

    return null
}

// Categorizar transação automaticamente baseado na descrição
const categorizeTransaction = (description: string, type: 'income' | 'expense' = 'expense'): string => {
    const desc = description.toLowerCase()

    if (type === 'income') {
        if (desc.includes('salário') || desc.includes('salario')) return 'Trabalho'
        if (desc.includes('freelance') || desc.includes('freela')) return 'Freelance'
        if (desc.includes('venda')) return 'Vendas'
        if (desc.includes('investimento') || desc.includes('dividendo')) return 'Investimentos'
        return 'Outros'
    }

    // Categorias de despesa
    if (desc.includes('ifood') || desc.includes('restaurante') || desc.includes('mercado') ||
        desc.includes('supermercado') || desc.includes('comida') || desc.includes('lanche')) {
        return 'Alimentação'
    }
    if (desc.includes('uber') || desc.includes('99') || desc.includes('gasolina') ||
        desc.includes('combustível') || desc.includes('transporte') || desc.includes('ônibus')) {
        return 'Transporte'
    }
    if (desc.includes('netflix') || desc.includes('spotify') || desc.includes('cinema') ||
        desc.includes('lazer') || desc.includes('jogo') || desc.includes('entretenimento')) {
        return 'Lazer'
    }
    if (desc.includes('luz') || desc.includes('água') || desc.includes('internet') ||
        desc.includes('aluguel') || desc.includes('conta')) {
        return 'Contas'
    }
    if (desc.includes('farmácia') || desc.includes('médico') || desc.includes('saúde') ||
        desc.includes('remédio') || desc.includes('hospital')) {
        return 'Saúde'
    }
    if (desc.includes('roupa') || desc.includes('sapato') || desc.includes('shopping') ||
        desc.includes('compra')) {
        return 'Compras'
    }
    if (desc.includes('curso') || desc.includes('livro') || desc.includes('escola') ||
        desc.includes('faculdade')) {
        return 'Educação'
    }

    return 'Outros'
}
