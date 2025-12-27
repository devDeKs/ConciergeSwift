"use client"

import { useState, useEffect, useCallback } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { Profile, Gender, getProfile, createProfile, updateProfileName } from '@/lib/profiles'

export function useProfile() {
    const { user } = useAuth()
    const [profile, setProfile] = useState<Profile | null>(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    // Carregar perfil
    const loadProfile = useCallback(async () => {
        if (!user) {
            setProfile(null)
            setLoading(false)
            return
        }

        setLoading(true)
        setError(null)

        try {
            const { data, error } = await getProfile()

            if (error && !error.message.includes('No rows')) {
                console.error('Error loading profile:', error)
            }

            setProfile(data)
        } catch (err) {
            console.error('Error loading profile:', err)
            setError('Erro ao carregar perfil')
        } finally {
            setLoading(false)
        }
    }, [user])

    // Carregar ao montar e quando usuário mudar
    useEffect(() => {
        loadProfile()
    }, [loadProfile])

    // Criar perfil
    const saveProfile = async (fullName: string, gender?: Gender) => {
        try {
            const { data, error } = await createProfile(fullName, gender)

            if (error) throw error
            if (data) {
                setProfile(data)
            }

            return { success: true, data }
        } catch (err) {
            console.error('Error saving profile:', err)
            return { success: false, error: 'Erro ao salvar perfil' }
        }
    }

    // Atualizar nome
    const updateName = async (fullName: string) => {
        try {
            const { data, error } = await updateProfileName(fullName)

            if (error) throw error
            if (data) {
                setProfile(data)
            }

            return { success: true, data }
        } catch (err) {
            console.error('Error updating name:', err)
            return { success: false, error: 'Erro ao atualizar nome' }
        }
    }

    // Obter primeiro nome para exibição
    const firstName = profile?.full_name?.split(' ')[0] || null

    // Obter prefixo de saudação baseado no gênero
    const greetingPrefix = profile?.gender === 'male' ? 'Sr. ' : profile?.gender === 'female' ? 'Sra. ' : ''

    return {
        profile,
        firstName,
        greetingPrefix,
        gender: profile?.gender,
        loading,
        error,
        saveProfile,
        updateName,
        refresh: loadProfile
    }
}

