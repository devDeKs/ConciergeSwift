import { supabase } from './supabase'

export interface Profile {
    id: string
    user_id: string
    full_name: string
    created_at: string
    updated_at: string
}

// Buscar perfil do usuário logado
export const getProfile = async () => {
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        return { data: null, error: new Error('Usuário não autenticado') }
    }

    const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('user_id', user.id)
        .single()

    return { data: data as Profile | null, error }
}

// Criar perfil após signup
export const createProfile = async (fullName: string) => {
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        return { data: null, error: new Error('Usuário não autenticado') }
    }

    // Check if profile already exists
    const { data: existing } = await supabase
        .from('profiles')
        .select('id')
        .eq('user_id', user.id)
        .single()

    if (existing) {
        // Update existing profile
        const { data, error } = await supabase
            .from('profiles')
            .update({ full_name: fullName, updated_at: new Date().toISOString() })
            .eq('user_id', user.id)
            .select()
            .single()
        return { data: data as Profile | null, error }
    }

    // Create new profile
    const { data, error } = await supabase
        .from('profiles')
        .insert({
            user_id: user.id,
            full_name: fullName
        })
        .select()
        .single()

    return { data: data as Profile | null, error }
}

// Atualizar nome
export const updateProfileName = async (fullName: string) => {
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
        return { data: null, error: new Error('Usuário não autenticado') }
    }

    const { data, error } = await supabase
        .from('profiles')
        .update({
            full_name: fullName,
            updated_at: new Date().toISOString()
        })
        .eq('user_id', user.id)
        .select()
        .single()

    return { data: data as Profile | null, error }
}
