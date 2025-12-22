"use client";

import { cn } from "@/lib/utils";
import { signIn } from "@/lib/supabase";
import { useRouter } from "next/navigation";
import React, { useState, useRef, useEffect } from "react";
import { ArrowRight, Mail, Lock, Eye, EyeOff, ArrowLeft, X, AlertCircle, Loader, Gem } from "lucide-react";
import { AnimatePresence, motion, useInView } from "framer-motion";
import Link from "next/link";

// --- Reusable Components ---
type MarginType = `${number}px` | `${number}%` | `${number}px ${number}px` | `${number}px ${number}px ${number}px ${number}px`;

interface BlurFadeProps {
    children: React.ReactNode;
    className?: string;
    duration?: number;
    delay?: number;
    yOffset?: number;
    inView?: boolean;
    inViewMargin?: MarginType;
    blur?: string;
}

function BlurFade({ children, className, duration = 0.4, delay = 0, yOffset = 6, inView = false, inViewMargin = "-50px" as MarginType, blur = "6px" }: BlurFadeProps) {
    const ref = useRef(null);
    const inViewResult = useInView(ref, { once: true, margin: inViewMargin as any });
    const isInView = !inView || inViewResult;
    return (
        <motion.div
            ref={ref}
            initial={{ y: yOffset, opacity: 0, filter: `blur(${blur})` }}
            animate={isInView ? { y: 0, opacity: 1, filter: `blur(0px)` } : { y: yOffset, opacity: 0, filter: `blur(${blur})` }}
            transition={{ delay: 0.04 + delay, duration, ease: "easeOut" }}
            className={className}
        >
            {children}
        </motion.div>
    );
}

// Glass Button
const GlassButton = React.forwardRef<
    HTMLButtonElement,
    React.ButtonHTMLAttributes<HTMLButtonElement> & {
        size?: "default" | "sm" | "icon";
        contentClassName?: string
    }
>(({ className, children, size = "default", contentClassName, ...props }, ref) => {
    const sizeClasses = {
        default: "h-12 px-5",
        sm: "h-10 px-4",
        icon: "h-8 w-8"
    };
    return (
        <button
            ref={ref}
            className={cn(
                "group relative rounded-full overflow-hidden transition-all duration-300",
                "bg-white/[0.03] hover:bg-white/[0.08]",
                "border border-white/10 hover:border-white/20",
                "shadow-[0_2px_8px_-2px_rgba(0,0,0,0.3),inset_0_1px_0_0_rgba(255,255,255,0.05)]",
                "hover:shadow-[0_4px_16px_-4px_rgba(0,0,0,0.4),inset_0_1px_0_0_rgba(255,255,255,0.1)]",
                "active:scale-[0.98]",
                sizeClasses[size],
                className
            )}
            {...props}
        >
            <div className={cn(
                "relative z-10 flex items-center justify-center gap-2 text-sm font-medium text-white/80",
                contentClassName
            )}>
                {children}
            </div>
        </button>
    );
});
GlassButton.displayName = "GlassButton";

// --- Default Logo ---
const DefaultLogo = () => (
    <div className="flex items-center gap-3">
        <div className="relative w-10 h-10 flex items-center justify-center">
            <div className="absolute inset-0 bg-gradient-to-br from-gold/30 to-gold/10 rounded-xl blur-md" />
            <div className="relative bg-gradient-to-br from-midnight-light to-midnight rounded-xl p-2 border border-gold/20">
                <Gem className="w-5 h-5 text-gold" />
            </div>
        </div>
        <span className="text-lg font-serif text-white/90 tracking-wide" style={{ fontFamily: 'var(--font-playfair)' }}>
            Concierge
        </span>
    </div>
);

export default function LoginPage() {
    const router = useRouter();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [showPassword, setShowPassword] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const passwordInputRef = useRef<HTMLInputElement>(null);
    const isEmailValid = /\S+@\S+\.\S+/.test(email);
    const isPasswordValid = password.length >= 6;

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!isEmailValid || !isPasswordValid) return;

        setIsLoading(true);
        setError(null);

        try {
            const { data, error } = await signIn(email, password);

            if (error) {
                if (error.message.includes("Invalid login")) {
                    setError("Email ou senha incorretos");
                } else {
                    setError(error.message || "Erro ao fazer login");
                }
                return;
            }

            // Success - redirect to dashboard
            router.push('/');
        } catch (err) {
            setError("Erro inesperado. Tente novamente.");
        } finally {
            setIsLoading(false);
        }
    };

    const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            if (e.currentTarget.type === 'email' && isEmailValid) {
                passwordInputRef.current?.focus();
            } else if (e.currentTarget.type === 'password' && isPasswordValid) {
                handleSubmit(e as any);
            }
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center relative overflow-hidden bg-background">
            {/* Background Effects */}
            <div className="absolute inset-0 pointer-events-none">
                <div className="absolute top-[-20%] left-[-10%] w-[60vw] h-[60vw] bg-midnight-light/30 rounded-full mix-blend-screen filter blur-[120px] animate-pulse" />
                <div className="absolute bottom-[-20%] right-[-10%] w-[50vw] h-[50vw] bg-gold/5 rounded-full mix-blend-screen filter blur-[100px] animate-pulse delay-1000" />
            </div>

            <div className="relative z-10 flex flex-col items-center gap-8 w-full max-w-[400px] mx-auto px-6">
                {/* Logo */}
                <BlurFade delay={0.1}>
                    <DefaultLogo />
                </BlurFade>

                {/* Title */}
                <BlurFade delay={0.2} className="text-center">
                    <h1 className="font-serif font-light text-4xl sm:text-5xl tracking-tight text-white drop-shadow-lg" style={{ fontFamily: 'var(--font-playfair)' }}>
                        Bem-vindo de volta
                    </h1>
                    <p className="mt-3 text-sm text-white/40">
                        Entre com sua conta para continuar
                    </p>
                </BlurFade>

                {/* Error Message */}
                <AnimatePresence>
                    {error && (
                        <motion.div
                            initial={{ opacity: 0, y: -10 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -10 }}
                            className="w-full p-4 bg-rose-500/10 border border-rose-500/20 rounded-xl flex items-center gap-3"
                        >
                            <AlertCircle className="w-5 h-5 text-rose-400 flex-shrink-0" />
                            <span className="text-sm text-rose-300">{error}</span>
                            <button onClick={() => setError(null)} className="ml-auto text-rose-400 hover:text-rose-300">
                                <X className="w-4 h-4" />
                            </button>
                        </motion.div>
                    )}
                </AnimatePresence>

                {/* Login Form */}
                <BlurFade delay={0.3} className="w-full">
                    <form onSubmit={handleSubmit} className="space-y-4">
                        {/* Email Input */}
                        <div className="relative">
                            <div className="glass-input-wrap w-full">
                                <div className="glass-input">
                                    <span className="glass-input-text-area"></span>
                                    <div className="relative z-10 flex-shrink-0 flex items-center justify-center w-10 pl-2">
                                        <Mail className="h-5 w-5 text-white/60" />
                                    </div>
                                    <input
                                        type="email"
                                        placeholder="Email"
                                        value={email}
                                        onChange={(e) => setEmail(e.target.value)}
                                        onKeyDown={handleKeyDown}
                                        className="relative z-10 h-full w-0 flex-grow bg-transparent text-white placeholder:text-white/30 focus:outline-none"
                                    />
                                </div>
                            </div>
                        </div>

                        {/* Password Input */}
                        <div className="relative">
                            <div className="glass-input-wrap w-full">
                                <div className="glass-input">
                                    <span className="glass-input-text-area"></span>
                                    <div className="relative z-10 flex-shrink-0 flex items-center justify-center w-10 pl-2">
                                        {isPasswordValid ? (
                                            <button
                                                type="button"
                                                onClick={() => setShowPassword(!showPassword)}
                                                className="text-white/60 hover:text-white transition-colors"
                                            >
                                                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                                            </button>
                                        ) : (
                                            <Lock className="h-5 w-5 text-white/60" />
                                        )}
                                    </div>
                                    <input
                                        ref={passwordInputRef}
                                        type={showPassword ? "text" : "password"}
                                        placeholder="Senha"
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                        onKeyDown={handleKeyDown}
                                        className="relative z-10 h-full w-0 flex-grow bg-transparent text-white placeholder:text-white/30 focus:outline-none"
                                    />
                                </div>
                            </div>
                        </div>

                        {/* Submit Button */}
                        <motion.button
                            type="submit"
                            disabled={!isEmailValid || !isPasswordValid || isLoading}
                            whileHover={{ scale: 1.02 }}
                            whileTap={{ scale: 0.98 }}
                            className={cn(
                                "w-full h-12 rounded-xl font-medium text-sm transition-all flex items-center justify-center gap-2",
                                isEmailValid && isPasswordValid && !isLoading
                                    ? "bg-gradient-to-r from-gold to-gold-light text-midnight shadow-lg shadow-gold/20 hover:shadow-gold/30"
                                    : "bg-white/5 text-white/30 cursor-not-allowed"
                            )}
                        >
                            {isLoading ? (
                                <Loader className="w-5 h-5 animate-spin" />
                            ) : (
                                <>
                                    Entrar
                                    <ArrowRight className="w-4 h-4" />
                                </>
                            )}
                        </motion.button>
                    </form>
                </BlurFade>

                {/* Sign Up Link */}
                <BlurFade delay={0.4}>
                    <Link href="/signup" className="text-sm text-white/40 hover:text-white/80 transition-colors">
                        Não tem uma conta? <span className="text-gold hover:underline">Criar conta</span>
                    </Link>
                </BlurFade>
            </div>
        </div>
    );
}
