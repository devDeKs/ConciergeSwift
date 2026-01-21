"use client";

import { motion } from "framer-motion";
import { User, Settings, Shield, CreditCard, Download, LogOut, ChevronRight, Bell, Moon } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/contexts/AuthContext";
import { useProfile } from "@/hooks/useProfile";

interface SettingsItemProps {
    icon: React.ElementType;
    label: string;
    description?: string;
    onClick?: () => void;
    danger?: boolean;
}

function SettingsItem({ icon: Icon, label, description, onClick, danger }: SettingsItemProps) {
    return (
        <button
            onClick={onClick}
            className={cn(
                "w-full flex items-center gap-3 p-3 rounded-xl transition-colors text-left",
                danger
                    ? "hover:bg-rose-50 active:bg-rose-100"
                    : "hover:bg-gray-50 active:bg-gray-100"
            )}
        >
            <div className={cn(
                "w-10 h-10 rounded-full flex items-center justify-center",
                danger ? "bg-rose-100" : "bg-gray-100"
            )}>
                <Icon className={cn("w-5 h-5", danger ? "text-rose-500" : "text-gray-600")} />
            </div>
            <div className="flex-1 min-w-0">
                <div className={cn("font-medium", danger ? "text-rose-600" : "text-gray-900")}>
                    {label}
                </div>
                {description && (
                    <div className="text-xs text-gray-500">{description}</div>
                )}
            </div>
            <ChevronRight className="w-5 h-5 text-gray-300" />
        </button>
    );
}

export function ProfileTab() {
    const { user, signOut } = useAuth();
    const { profile } = useProfile();

    const displayName = (profile as { display_name?: string })?.display_name || user?.email?.split('@')[0] || 'Usuário';
    const email = user?.email || 'Não conectado';
    const initials = displayName.charAt(0).toUpperCase();

    const handleSignOut = async () => {
        await signOut();
    };

    return (
        <div className="flex flex-col h-full bg-background">
            {/* Dark Header Section */}
            <div className="bg-gradient-to-b from-midnight to-midnight-light pt-12 pb-8 px-5">
                <h1
                    className="text-xl font-serif text-white tracking-wide text-center mb-6"
                    style={{ fontFamily: 'var(--font-playfair)' }}
                >
                    Perfil
                </h1>

                {/* Profile Card */}
                <motion.div
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="flex items-center gap-4 bg-white/5 border border-white/10 rounded-2xl p-4"
                >
                    {/* Avatar */}
                    <div className="w-16 h-16 rounded-full bg-gradient-to-br from-gold to-gold-dark flex items-center justify-center text-midnight font-bold text-xl">
                        {initials}
                    </div>

                    {/* Info */}
                    <div className="flex-1 min-w-0">
                        <div className="font-semibold text-white text-lg truncate">{displayName}</div>
                        <div className="text-white/50 text-sm truncate">{email}</div>
                        <div className="mt-1">
                            <span className="px-2 py-0.5 rounded-full bg-gold/20 text-gold text-[10px] font-medium uppercase tracking-wider">
                                Premium
                            </span>
                        </div>
                    </div>
                </motion.div>
            </div>

            {/* Light Content Section */}
            <div className="flex-1 bg-white rounded-t-3xl -mt-4 overflow-auto">
                <div className="p-5 space-y-6">
                    {/* Account Section */}
                    <div>
                        <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2 px-1">
                            Conta
                        </h3>
                        <div className="bg-gray-50 rounded-xl overflow-hidden">
                            <SettingsItem
                                icon={User}
                                label="Meus Dados"
                                description="Editar informações pessoais"
                            />
                            <SettingsItem
                                icon={CreditCard}
                                label="Moeda"
                                description="BRL - Real Brasileiro"
                            />
                        </div>
                    </div>

                    {/* Preferences Section */}
                    <div>
                        <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2 px-1">
                            Preferências
                        </h3>
                        <div className="bg-gray-50 rounded-xl overflow-hidden">
                            <SettingsItem
                                icon={Bell}
                                label="Notificações"
                                description="Alertas e lembretes"
                            />
                            <SettingsItem
                                icon={Moon}
                                label="Aparência"
                                description="Tema escuro ativado"
                            />
                        </div>
                    </div>

                    {/* Data Section */}
                    <div>
                        <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2 px-1">
                            Dados
                        </h3>
                        <div className="bg-gray-50 rounded-xl overflow-hidden">
                            <SettingsItem
                                icon={Download}
                                label="Exportar Dados"
                                description="Baixar em CSV"
                            />
                            <SettingsItem
                                icon={Shield}
                                label="Privacidade"
                                description="Segurança e dados"
                            />
                        </div>
                    </div>

                    {/* Logout */}
                    {user && (
                        <div>
                            <div className="bg-rose-50/50 rounded-xl overflow-hidden">
                                <SettingsItem
                                    icon={LogOut}
                                    label="Sair da Conta"
                                    onClick={handleSignOut}
                                    danger
                                />
                            </div>
                        </div>
                    )}

                    {/* Version Info */}
                    <div className="text-center text-xs text-gray-400 pt-4">
                        Concierge Finance v1.0.0
                    </div>
                </div>
            </div>
        </div>
    );
}
