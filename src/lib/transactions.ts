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
    const msg = message.trim().toLowerCase()

    // Extract amount from anywhere in the message (handles "50 reais", "R$ 50", "50")
    const amountPatterns = [
        /r?\$?\s*(\d+(?:[.,]\d{1,2})?)\s*(?:reais|real)?/i,
        /(\d+(?:[.,]\d{1,2})?)\s*(?:reais|real|r\$)/i,
    ]

    let extractedAmount = 0
    for (const pattern of amountPatterns) {
        const match = msg.match(pattern)
        if (match) {
            extractedAmount = parseFloat(match[1].replace(',', '.'))
            if (!isNaN(extractedAmount) && extractedAmount > 0) break
        }
    }

    if (extractedAmount <= 0) return null

    // Determine type based on keywords
    const expenseKeywords = ['gastei', 'paguei', 'comprei', 'gasto', 'despesa', 'compra', 'pago']
    const incomeKeywords = ['recebi', 'ganhei', 'entrou', 'receita', 'renda', 'salário', 'salario']

    let type: 'income' | 'expense' = 'expense'
    if (incomeKeywords.some(k => msg.includes(k))) {
        type = 'income'
    }

    // Extract description - try to find meaningful words
    let description = ''

    // Common known categories/merchants to detect
    const knownTerms: { [key: string]: { desc: string; cat: string } } = {
        'ifood': { desc: 'iFood', cat: 'Alimentação' },
        'uber': { desc: 'Uber', cat: 'Transporte' },
        '99': { desc: '99 Taxi', cat: 'Transporte' },
        'netflix': { desc: 'Netflix', cat: 'Lazer' },
        'spotify': { desc: 'Spotify', cat: 'Lazer' },
        'mercado': { desc: 'Mercado', cat: 'Alimentação' },
        'supermercado': { desc: 'Supermercado', cat: 'Alimentação' },
        'restaurante': { desc: 'Restaurante', cat: 'Alimentação' },
        'luz': { desc: 'Conta de Luz', cat: 'Contas' },
        'água': { desc: 'Conta de Água', cat: 'Contas' },
        'agua': { desc: 'Conta de Água', cat: 'Contas' },
        'internet': { desc: 'Internet', cat: 'Contas' },
        'aluguel': { desc: 'Aluguel', cat: 'Contas' },
        'salário': { desc: 'Salário', cat: 'Trabalho' },
        'salario': { desc: 'Salário', cat: 'Trabalho' },
        'freelance': { desc: 'Freelance', cat: 'Freelance' },
        'farmácia': { desc: 'Farmácia', cat: 'Saúde' },
        'farmacia': { desc: 'Farmácia', cat: 'Saúde' },
        'gasolina': { desc: 'Gasolina', cat: 'Transporte' },
        'combustível': { desc: 'Combustível', cat: 'Transporte' },
        'combustivel': { desc: 'Combustível', cat: 'Transporte' },
    }

    let category = type === 'income' ? 'Outros' : 'Outros'

    // Check for known terms
    for (const [term, info] of Object.entries(knownTerms)) {
        if (msg.includes(term)) {
            description = info.desc
            category = info.cat
            break
        }
    }

    // If no known term found, try to extract a simple description
    if (!description) {
        // Remove common words and numbers to find the subject
        const cleanMsg = msg
            .replace(/gastei|paguei|comprei|recebi|ganhei|entrou/gi, '')
            .replace(/r?\$?\s*\d+(?:[.,]\d{1,2})?\s*(?:reais|real)?/gi, '')
            .replace(/hoje|ontem|agora|amanhã|no|na|em|de|do|da|um|uma|com|por/gi, '')
            .trim()

        if (cleanMsg.length > 0 && cleanMsg.length < 50) {
            description = cleanMsg.charAt(0).toUpperCase() + cleanMsg.slice(1)
        } else {
            description = type === 'income' ? 'Receita' : 'Despesa'
        }

        category = categorizeTransaction(description, type)
    }

    return {
        amount: extractedAmount,
        description,
        type,
        category
    }
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
