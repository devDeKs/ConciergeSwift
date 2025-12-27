import { cn } from "@/lib/utils";
import { signUp } from "@/lib/supabase";
import { useRouter } from "next/navigation";
import Link from "next/link";
import React, { useState, useRef, useEffect, forwardRef, useImperativeHandle, useMemo, useCallback, createContext, Children } from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { ArrowRight, Mail, Gem, Lock, Eye, EyeOff, ArrowLeft, X, AlertCircle, PartyPopper, Loader, User, UserCircle } from "lucide-react";
import { AnimatePresence, motion, useInView, Variants, Transition } from "framer-motion";
import type { Gender } from "@/lib/profiles";

// --- CONFETTI LOGIC ---
import type { GlobalOptions as ConfettiGlobalOptions, CreateTypes as ConfettiInstance, Options as ConfettiOptions } from "canvas-confetti"
import confetti from "canvas-confetti"

type Api = { fire: (options?: ConfettiOptions) => void }
export type ConfettiRef = Api | null
const ConfettiContext = createContext<Api>({} as Api)

const Confetti = forwardRef<ConfettiRef, React.ComponentPropsWithRef<"canvas"> & { options?: ConfettiOptions; globalOptions?: ConfettiGlobalOptions; manualstart?: boolean }>((props, ref) => {
    const { options, globalOptions = { resize: true, useWorker: true }, manualstart = false, ...rest } = props
    const instanceRef = useRef<ConfettiInstance | null>(null)
    const canvasRef = useCallback((node: HTMLCanvasElement) => {
        if (node !== null) {
            if (instanceRef.current) return
            instanceRef.current = confetti.create(node, { ...globalOptions, resize: true })
        } else {
            if (instanceRef.current) {
                instanceRef.current.reset()
                instanceRef.current = null
            }
        }
    }, [globalOptions])
    const fire = useCallback((opts = {}) => instanceRef.current?.({ ...options, ...opts }), [options])
    const api = useMemo(() => ({ fire }), [fire])
    useImperativeHandle(ref, () => api, [api])
    useEffect(() => { if (!manualstart) fire() }, [manualstart, fire])
    return <canvas ref={canvasRef} {...rest} />
})
Confetti.displayName = "Confetti";

// --- TEXT LOOP ANIMATION COMPONENT ---
type TextLoopProps = { children: React.ReactNode[]; className?: string; interval?: number; transition?: Transition; variants?: Variants; onIndexChange?: (index: number) => void; stopOnEnd?: boolean; };
export function TextLoop({ children, className, interval = 2, transition = { duration: 0.3 }, variants, onIndexChange, stopOnEnd = false }: TextLoopProps) {
    const [currentIndex, setCurrentIndex] = useState(0);
    const items = Children.toArray(children);
    useEffect(() => {
        const intervalMs = interval * 1000;
        const timer = setInterval(() => {
            setCurrentIndex((current) => {
                if (stopOnEnd && current === items.length - 1) {
                    clearInterval(timer);
                    return current;
                }
                const next = (current + 1) % items.length;
                onIndexChange?.(next);
                return next;
            });
        }, intervalMs);
        return () => clearInterval(timer);
    }, [items.length, interval, onIndexChange, stopOnEnd]);
    const motionVariants: Variants = {
        initial: { y: 20, opacity: 0 },
        animate: { y: 0, opacity: 1 },
        exit: { y: -20, opacity: 0 },
    };
    return (
        <div className={cn('relative inline-block whitespace-nowrap', className)}>
            <AnimatePresence mode='popLayout' initial={false}>
                <motion.div key={currentIndex} initial='initial' animate='animate' exit='exit' transition={transition} variants={variants || motionVariants}>
                    {items[currentIndex]}
                </motion.div>
            </AnimatePresence>
        </div>
    );
}

// --- BUILT-IN BLUR FADE ANIMATION COMPONENT ---
interface BlurFadeProps { children: React.ReactNode; className?: string; variant?: { hidden: { y: number }; visible: { y: number } }; duration?: number; delay?: number; yOffset?: number; inView?: boolean; inViewMargin?: `${number}px` | `${number}%` | `${number}px ${number}px` | `${number}px ${number}px ${number}px ${number}px`; blur?: string; }
function BlurFade({ children, className, variant, duration = 0.4, delay = 0, yOffset = 6, inView = true, inViewMargin = "-50px", blur = "6px" }: BlurFadeProps) {
    const ref = useRef(null);
    const inViewResult = useInView(ref, { once: true, margin: inViewMargin as any });
    const isInView = !inView || inViewResult;
    const defaultVariants: Variants = {
        hidden: { y: yOffset, opacity: 0, filter: `blur(${blur})` },
        visible: { y: -yOffset, opacity: 1, filter: `blur(0px)` },
    };
    const combinedVariants = variant || defaultVariants;
    return (
        <motion.div ref={ref} initial="hidden" animate={isInView ? "visible" : "hidden"} exit="hidden" variants={combinedVariants} transition={{ delay: 0.04 + delay, duration, ease: "easeOut" }} className={className}>
            {children}
        </motion.div>
    );
}


// --- BUILT-IN GLASS BUTTON COMPONENT (WITH CLICK FIX) ---
const glassButtonVariants = cva("relative isolate all-unset cursor-pointer rounded-full transition-all", { variants: { size: { default: "text-base font-medium", sm: "text-sm font-medium", lg: "text-lg font-medium", icon: "h-10 w-10" } }, defaultVariants: { size: "default" } });
const glassButtonTextVariants = cva("glass-button-text relative block select-none tracking-tighter", { variants: { size: { default: "px-6 py-3.5", sm: "px-4 py-2", lg: "px-8 py-4", icon: "flex h-10 w-10 items-center justify-center" } }, defaultVariants: { size: "default" } });
export interface GlassButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement>, VariantProps<typeof glassButtonVariants> { contentClassName?: string; }
const GlassButton = React.forwardRef<HTMLButtonElement, GlassButtonProps>(
    ({ className, children, size, contentClassName, onClick, ...props }, ref) => {
        const handleWrapperClick = (e: React.MouseEvent<HTMLDivElement>) => {
            const button = e.currentTarget.querySelector('button');
            if (button && e.target !== button) button.click();
        };
        return (
            <div className={cn("glass-button-wrap cursor-pointer rounded-full relative", className)} onClick={handleWrapperClick}>
                <button className={cn("glass-button relative z-10", glassButtonVariants({ size }))} ref={ref} onClick={onClick} {...props}>
                    <span className={cn(glassButtonTextVariants({ size }), contentClassName)}>{children}</span>
                </button>
                <div className="glass-button-shadow rounded-full pointer-events-none"></div>
            </div>
        );
    }
);
GlassButton.displayName = "GlassButton";


// --- THEME-AWARE SVG GRADIENT BACKGROUND WITH SUBTLE ANIMATION ---
const GradientBackground = () => (
    <>
        <style>
            {` @keyframes float1 { 0% { transform: translate(0, 0); } 50% { transform: translate(-10px, 10px); } 100% { transform: translate(0, 0); } } @keyframes float2 { 0% { transform: translate(0, 0); } 50% { transform: translate(10px, -10px); } 100% { transform: translate(0, 0); } } `}
        </style>
        <svg width="100%" height="100%" viewBox="0 0 800 600" fill="none" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid slice" className="absolute top-0 left-0 w-full h-full pointer-events-none opacity-40">
            <defs>
                {/* Updated to use Gold/Midnight Palette */}
                {/* Gold Primary Gradient */}
                <linearGradient id="rev_grad1" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" style={{ stopColor: 'var(--color-gold)', stopOpacity: 0.4 }} />
                    <stop offset="100%" style={{ stopColor: 'var(--color-gold-dark)', stopOpacity: 0.2 }} />
                </linearGradient>

                {/* Midnight/Blue Secondary Gradient */}
                <linearGradient id="rev_grad2" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" style={{ stopColor: 'var(--color-midnight-light)', stopOpacity: 0.5 }} />
                    <stop offset="50%" style={{ stopColor: 'var(--color-secondary)', stopOpacity: 0.4 }} />
                    <stop offset="100%" style={{ stopColor: 'var(--color-midnight)', stopOpacity: 0.3 }} />
                </linearGradient>

                {/* Accent/Gold Glow */}
                <radialGradient id="rev_grad3" cx="50%" cy="50%" r="50%">
                    <stop offset="0%" style={{ stopColor: 'var(--color-gold-light)', stopOpacity: 0.3 }} />
                    <stop offset="100%" style={{ stopColor: 'var(--color-midnight)', stopOpacity: 0.1 }} />
                </radialGradient>

                <filter id="rev_blur1" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="35" /></filter>
                <filter id="rev_blur2" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="25" /></filter>
                <filter id="rev_blur3" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="45" /></filter>
            </defs>
            <g style={{ animation: 'float1 20s ease-in-out infinite' }}>
                <ellipse cx="200" cy="500" rx="250" ry="180" fill="url(#rev_grad1)" filter="url(#rev_blur1)" transform="rotate(-30 200 500)" />
                <rect x="500" y="100" width="300" height="250" rx="80" fill="url(#rev_grad2)" filter="url(#rev_blur2)" transform="rotate(15 650 225)" />
            </g>
            <g style={{ animation: 'float2 25s ease-in-out infinite' }}>
                <circle cx="650" cy="450" r="150" fill="url(#rev_grad3)" filter="url(#rev_blur3)" opacity="0.7" />
                <ellipse cx="50" cy="150" rx="180" ry="120" fill="var(--color-secondary)" filter="url(#rev_blur2)" opacity="0.8" />
            </g>
        </svg>
    </>
);


// --- CHILD COMPONENTS ---


const modalSteps = [
    { message: "Criando sua conta...", icon: <Loader className="w-12 h-12 text-gold animate-spin" /> },
    { message: "Verificando dados...", icon: <Loader className="w-12 h-12 text-gold animate-spin" /> },
    { message: "Finalizando...", icon: <Loader className="w-12 h-12 text-gold animate-spin" /> },
    { message: "Bem-vindo a bordo!", icon: <PartyPopper className="w-12 h-12 text-gold-light" /> }
];
const TEXT_LOOP_INTERVAL = 1.5;

const DefaultLogo = () => (<div className="bg-gold/20 text-gold rounded-full p-2 border border-gold/30"> <Gem className="h-5 w-5" /> </div>);

// --- MAIN COMPONENT ---
interface AuthComponentProps {
    logo?: React.ReactNode;
    brandName?: string;
}

export const AuthComponent = ({ logo = <DefaultLogo />, brandName = "Concierge Finance" }: AuthComponentProps) => {
    const router = useRouter();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const [fullName, setFullName] = useState("");
    const [gender, setGender] = useState<Gender | undefined>(undefined);
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);
    const [authStep, setAuthStep] = useState<"email" | "password" | "confirmPassword" | "name" | "gender">("email");
    const [modalStatus, setModalStatus] = useState<'closed' | 'loading' | 'error' | 'success'>('closed');
    const [modalErrorMessage, setModalErrorMessage] = useState('');
    const confettiRef = useRef<ConfettiRef>(null);

    const isEmailValid = /\S+@\S+\.\S+/.test(email);
    const isPasswordValid = password.length >= 6;
    const isConfirmPasswordValid = confirmPassword.length >= 6;
    const isNameValid = fullName.trim().length >= 2;

    const passwordInputRef = useRef<HTMLInputElement>(null);
    const confirmPasswordInputRef = useRef<HTMLInputElement>(null);
    const nameInputRef = useRef<HTMLInputElement>(null);

    const fireSideCanons = () => {
        const fire = confettiRef.current?.fire;
        if (fire) {
            const defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 100, colors: ['#B4975A', '#D6C08D', '#7D6635', '#ffffff'] };
            const particleCount = 50;
            fire({ ...defaults, particleCount, origin: { x: 0, y: 1 }, angle: 60 });
            fire({ ...defaults, particleCount, origin: { x: 1, y: 1 }, angle: 120 });
        }
    };

    const handleFinalSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (modalStatus !== 'closed' || authStep !== 'gender') return;

        setModalStatus('loading');

        try {
            // 1. Criar conta no Supabase Auth
            const { data, error } = await signUp(email, password);

            if (error) {
                setModalErrorMessage(error.message || "Erro ao criar conta");
                setModalStatus('error');
                return;
            }

            // 2. Criar perfil com nome (será feito após login automático)
            // O Supabase Auth faz login automático após signup
            const { createProfile } = await import('@/lib/profiles');
            const profileResult = await createProfile(fullName.trim(), gender);

            if (profileResult.error) {
                console.error('Profile creation error:', profileResult.error);
                // Não bloquear o fluxo, perfil pode ser criado depois
            }

            // Success - show animation then redirect
            const loadingStepsCount = modalSteps.length - 1;
            const totalDuration = loadingStepsCount * TEXT_LOOP_INTERVAL * 1000;

            setTimeout(() => {
                fireSideCanons();
                setModalStatus('success');

                // Redirect to dashboard after success popup
                setTimeout(() => {
                    router.push('/');
                }, 2000);
            }, totalDuration);
        } catch (err) {
            setModalErrorMessage("Erro inesperado. Tente novamente.");
            setModalStatus('error');
        }
    };

    const handleProgressStep = () => {
        if (authStep === 'email') {
            if (isEmailValid) setAuthStep("password");
        } else if (authStep === 'password') {
            if (isPasswordValid) setAuthStep("confirmPassword");
        } else if (authStep === 'confirmPassword') {
            if (password !== confirmPassword) {
                setModalErrorMessage("As senhas não coincidem!");
                setModalStatus('error');
                return;
            }
            if (isConfirmPasswordValid) setAuthStep("name");
        } else if (authStep === 'name') {
            if (isNameValid) setAuthStep("gender");
        }
    };

    const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            if (authStep === 'name' && isNameValid) {
                // Trigger form submit
                const form = e.currentTarget.closest('form');
                form?.requestSubmit();
            } else {
                handleProgressStep();
            }
        }
    };

    const handleGoBack = () => {
        if (authStep === 'gender') {
            setAuthStep('name');
        } else if (authStep === 'name') {
            setAuthStep('confirmPassword');
        } else if (authStep === 'confirmPassword') {
            setAuthStep('password');
            setConfirmPassword('');
        }
        else if (authStep === 'password') setAuthStep('email');
    };

    const closeModal = () => {
        setModalStatus('closed');
        setModalErrorMessage('');
    };

    useEffect(() => {
        if (authStep === 'password') setTimeout(() => passwordInputRef.current?.focus(), 500);
        else if (authStep === 'confirmPassword') setTimeout(() => confirmPasswordInputRef.current?.focus(), 500);
        else if (authStep === 'name') setTimeout(() => nameInputRef.current?.focus(), 500);
    }, [authStep]);

    useEffect(() => {
        if (modalStatus === 'success') {
            fireSideCanons();
        }
    }, [modalStatus]);


    const Modal = () => (
        <AnimatePresence>
            {modalStatus !== 'closed' && (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-md">
                    <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.9, opacity: 0 }} className="relative bg-[#0b1021]/90 border border-gold/20 rounded-2xl p-8 w-full max-w-sm flex flex-col items-center gap-4 mx-2 shadow-2xl">
                        {(modalStatus === 'error' || modalStatus === 'success') && <button onClick={closeModal} className="absolute top-2 right-2 p-1 text-white/50 hover:text-white transition-colors"><X className="w-5 h-5" /></button>}
                        {modalStatus === 'error' && <>
                            <AlertCircle className="w-12 h-12 text-rose-500" />
                            <p className="text-lg font-medium text-white">{modalErrorMessage}</p>
                            <GlassButton onClick={closeModal} size="sm" className="mt-4">Tentar Novamente</GlassButton>
                        </>}
                        {modalStatus === 'loading' &&
                            <TextLoop interval={TEXT_LOOP_INTERVAL} stopOnEnd={true}>
                                {modalSteps.slice(0, -1).map((step, i) =>
                                    <div key={i} className="flex flex-col items-center gap-4">
                                        {step.icon}
                                        <p className="text-lg font-medium text-white">{step.message}</p>
                                    </div>
                                )}
                            </TextLoop>
                        }
                        {modalStatus === 'success' &&
                            <div className="flex flex-col items-center gap-4">
                                {modalSteps[modalSteps.length - 1].icon}
                                <p className="text-lg font-medium text-white">{modalSteps[modalSteps.length - 1].message}</p>
                            </div>
                        }
                    </motion.div>
                </motion.div>
            )}
        </AnimatePresence>
    );

    return (
        <div className="bg-background min-h-screen w-full flex flex-col font-sans selection:bg-gold/20 selection:text-gold overflow-hidden">
            <style>{`
            input[type="password"]::-ms-reveal, input[type="password"]::-ms-clear { display: none !important; } input[type="password"]::-webkit-credentials-auto-fill-button, input[type="password"]::-webkit-strong-password-auto-fill-button { display: none !important; } input:-webkit-autofill, input:-webkit-autofill:hover, input:-webkit-autofill:focus, input:-webkit-autofill:active { -webkit-box-shadow: 0 0 0 30px transparent inset !important; -webkit-text-fill-color: var(--foreground) !important; background-color: transparent !important; background-clip: content-box !important; transition: background-color 5000s ease-in-out 0s !important; color: var(--foreground) !important; caret-color: var(--foreground) !important; } input:autofill { background-color: transparent !important; background-clip: content-box !important; -webkit-text-fill-color: var(--foreground) !important; color: var(--foreground) !important; } input:-internal-autofill-selected { background-color: transparent !important; background-image: none !important; color: var(--foreground) !important; -webkit-text-fill-color: var(--foreground) !important; } input:-webkit-autofill::first-line { color: var(--foreground) !important; -webkit-text-fill-color: var(--foreground) !important; }
            @property --angle-1 { syntax: "<angle>"; inherits: false; initial-value: -75deg; } @property --angle-2 { syntax: "<angle>"; inherits: false; initial-value: -45deg; }
            .glass-button-wrap { --anim-time: 400ms; --anim-ease: cubic-bezier(0.25, 1, 0.5, 1); --border-width: clamp(1px, 0.0625em, 4px); position: relative; z-index: 2; transform-style: preserve-3d; transition: transform var(--anim-time) var(--anim-ease); } .glass-button-wrap:has(.glass-button:active) { transform: rotateX(25deg); } .glass-button-shadow { --shadow-cutoff-fix: 2em; position: absolute; width: calc(100% + var(--shadow-cutoff-fix)); height: calc(100% + var(--shadow-cutoff-fix)); top: calc(0% - var(--shadow-cutoff-fix) / 2); left: calc(0% - var(--shadow-cutoff-fix) / 2); filter: blur(clamp(2px, 0.125em, 12px)); transition: filter var(--anim-time) var(--anim-ease); pointer-events: none; z-index: 0; } .glass-button-shadow::after { content: ""; position: absolute; inset: 0; border-radius: 9999px; background: linear-gradient(180deg, oklch(from var(--foreground) l c h / 20%), oklch(from var(--foreground) l c h / 10%)); width: calc(100% - var(--shadow-cutoff-fix) - 0.25em); height: calc(100% - var(--shadow-cutoff-fix) - 0.25em); top: calc(var(--shadow-cutoff-fix) - 0.5em); left: calc(var(--shadow-cutoff-fix) - 0.875em); padding: 0.125em; box-sizing: border-box; mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0); mask-composite: exclude; transition: all var(--anim-time) var(--anim-ease); opacity: 1; }
            .glass-button { -webkit-tap-highlight-color: transparent; backdrop-filter: blur(clamp(1px, 0.125em, 4px)); transition: all var(--anim-time) var(--anim-ease); background: linear-gradient(-75deg, oklch(from var(--background) l c h / 5%), oklch(from var(--background) l c h / 20%), oklch(from var(--background) l c h / 5%)); box-shadow: inset 0 0.125em 0.125em oklch(from var(--foreground) l c h / 5%), inset 0 -0.125em 0.125em oklch(from var(--background) l c h / 50%), 0 0.25em 0.125em -0.125em oklch(from var(--foreground) l c h / 20%), 0 0 0.1em 0.25em inset oklch(from var(--background) l c h / 20%), 0 0 0 0 oklch(from var(--background) l c h); } .glass-button:hover { transform: scale(0.975); backdrop-filter: blur(0.01em); box-shadow: inset 0 0.125em 0.125em oklch(from var(--foreground) l c h / 5%), inset 0 -0.125em 0.125em oklch(from var(--background) l c h / 50%), 0 0.15em 0.05em -0.1em oklch(from var(--foreground) l c h / 25%), 0 0 0.05em 0.1em inset oklch(from var(--background) l c h / 50%), 0 0 0 0 oklch(from var(--background) l c h); } .glass-button-text { color: oklch(from var(--foreground) l c h / 90%); text-shadow: 0em 0.25em 0.05em oklch(from var(--foreground) l c h / 10%); transition: all var(--anim-time) var(--anim-ease); } .glass-button:hover .glass-button-text { text-shadow: 0.025em 0.025em 0.025em oklch(from var(--foreground) l c h / 12%); } .glass-button-text::after { content: ""; display: block; position: absolute; width: calc(100% - var(--border-width)); height: calc(100% - var(--border-width)); top: calc(0% + var(--border-width) / 2); left: calc(0% + var(--border-width) / 2); box-sizing: border-box; border-radius: 9999px; overflow: clip; background: linear-gradient(var(--angle-2), transparent 0%, oklch(from var(--background) l c h / 50%) 40% 50%, transparent 55%); z-index: 3; mix-blend-mode: screen; pointer-events: none; background-size: 200% 200%; background-position: 0% 50%; transition: background-position calc(var(--anim-time) * 1.25) var(--anim-ease), --angle-2 calc(var(--anim-time) * 1.25) var(--anim-ease); } .glass-button:hover .glass-button-text::after { background-position: 25% 50%; } .glass-button:active .glass-button-text::after { background-position: 50% 15%; --angle-2: -15deg; } .glass-button::after { content: ""; position: absolute; z-index: 1; inset: 0; border-radius: 9999px; width: calc(100% + var(--border-width)); height: calc(100% + var(--border-width)); top: calc(0% - var(--border-width) / 2); left: calc(0% - var(--border-width) / 2); padding: var(--border-width); box-sizing: border-box; background: conic-gradient(from var(--angle-1) at 50% 50%, oklch(from var(--foreground) l c h / 50%) 0%, transparent 5% 40%, oklch(from var(--foreground) l c h / 50%) 50%, transparent 60% 95%, oklch(from var(--foreground) l c h / 50%) 100%), linear-gradient(180deg, oklch(from var(--background) l c h / 50%), oklch(from var(--background) l c h / 50%)); mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0); mask-composite: exclude; transition: all var(--anim-time) var(--anim-ease), --angle-1 500ms ease; box-shadow: inset 0 0 0 calc(var(--border-width) / 2) oklch(from var(--background) l c h / 50%); pointer-events: none; } .glass-button:hover::after { --angle-1: -125deg; } .glass-button:active::after { --angle-1: -75deg; } .glass-button-wrap:has(.glass-button:hover) .glass-button-shadow { filter: blur(clamp(2px, 0.0625em, 6px)); } .glass-button-wrap:has(.glass-button:hover) .glass-button-shadow::after { top: calc(var(--shadow-cutoff-fix) - 0.875em); opacity: 1; } .glass-button-wrap:has(.glass-button:active) .glass-button-shadow { filter: blur(clamp(2px, 0.125em, 12px)); } .glass-button-wrap:has(.glass-button:active) .glass-button-shadow::after { top: calc(var(--shadow-cutoff-fix) - 0.5em); opacity: 0.75; } .glass-button-wrap:has(.glass-button:active) .glass-button-text { text-shadow: 0.025em 0.25em 0.05em oklch(from var(--foreground) l c h / 12%); } .glass-button-wrap:has(.glass-button:active) .glass-button { box-shadow: inset 0 0.125em 0.125em oklch(from var(--foreground) l c h / 5%), inset 0 -0.125em 0.125em oklch(from var(--background) l c h / 50%), 0 0.125em 0.125em -0.125em oklch(from var(--foreground) l c h / 20%), 0 0 0.1em 0.25em inset oklch(from var(--background) l c h / 20%), 0 0.225em 0.05em 0 oklch(from var(--foreground) l c h / 5%), 0 0.25em 0 0 oklch(from var(--background) l c h / 75%), inset 0 0.25em 0.05em 0 oklch(from var(--foreground) l c h / 15%); } @media (hover: none) and (pointer: coarse) { .glass-button::after, .glass-button:hover::after, .glass-button:active::after { --angle-1: -75deg; } .glass-button .glass-button-text::after, .glass-button:active .glass-button-text::after { --angle-2: -45deg; } }
            .glass-input-wrap { position: relative; z-index: 2; transform-style: preserve-3d; border-radius: 9999px; } .glass-input { display: flex; position: relative; width: 100%; align-items: center; gap: 0.5rem; border-radius: 9999px; padding: 0.25rem; -webkit-tap-highlight-color: transparent; backdrop-filter: blur(clamp(1px, 0.125em, 4px)); transition: all 400ms cubic-bezier(0.25, 1, 0.5, 1); background: linear-gradient(-75deg, oklch(from var(--background) l c h / 5%), oklch(from var(--background) l c h / 20%), oklch(from var(--background) l c h / 5%)); box-shadow: inset 0 0.125em 0.125em oklch(from var(--foreground) l c h / 5%), inset 0 -0.125em 0.125em oklch(from var(--background) l c h / 50%), 0 0.25em 0.125em -0.125em oklch(from var(--foreground) l c h / 20%), 0 0 0.1em 0.25em inset oklch(from var(--background) l c h / 20%), 0 0 0 0 oklch(from var(--background) l c h); } .glass-input-wrap:focus-within .glass-input { backdrop-filter: blur(0.01em); box-shadow: inset 0 0.125em 0.125em oklch(from var(--foreground) l c h / 5%), inset 0 -0.125em 0.125em oklch(from var(--background) l c h / 50%), 0 0.15em 0.05em -0.1em oklch(from var(--foreground) l c h / 25%), 0 0 0.05em 0.1em inset oklch(from var(--background) l c h / 50%), 0 0 0 0 oklch(from var(--background) l c h); } .glass-input::after { content: ""; position: absolute; z-index: 1; inset: 0; border-radius: 9999px; width: calc(100% + clamp(1px, 0.0625em, 4px)); height: calc(100% + clamp(1px, 0.0625em, 4px)); top: calc(0% - clamp(1px, 0.0625em, 4px) / 2); left: calc(0% - clamp(1px, 0.0625em, 4px) / 2); padding: clamp(1px, 0.0625em, 4px); box-sizing: border-box; background: conic-gradient(from var(--angle-1) at 50% 50%, oklch(from var(--foreground) l c h / 50%) 0%, transparent 5% 40%, oklch(from var(--foreground) l c h / 50%) 50%, transparent 60% 95%, oklch(from var(--foreground) l c h / 50%) 100%), linear-gradient(180deg, oklch(from var(--background) l c h / 50%), oklch(from var(--background) l c h / 50%)); mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0); mask-composite: exclude; transition: all 400ms cubic-bezier(0.25, 1, 0.5, 1), --angle-1 500ms ease; box-shadow: inset 0 0 0 calc(clamp(1px, 0.0625em, 4px) / 2) oklch(from var(--background) l c h / 50%); pointer-events: none; } .glass-input-wrap:focus-within .glass-input::after { --angle-1: -125deg; } .glass-input-text-area { position: absolute; inset: 0; border-radius: 9999px; pointer-events: none; } .glass-input-text-area::after { content: ""; display: block; position: absolute; width: calc(100% - clamp(1px, 0.0625em, 4px)); height: calc(100% - clamp(1px, 0.0625em, 4px)); top: calc(0% + clamp(1px, 0.0625em, 4px) / 2); left: calc(0% + clamp(1px, 0.0625em, 4px) / 2); box-sizing: border-box; border-radius: 9999px; overflow: clip; background: linear-gradient(var(--angle-2), transparent 0%, oklch(from var(--background) l c h / 50%) 40% 50%, transparent 55%); z-index: 3; mix-blend-mode: screen; pointer-events: none; background-size: 200% 200%; background-position: 0% 50%; transition: background-position calc(400ms * 1.25) cubic-bezier(0.25, 1, 0.5, 1), --angle-2 calc(400ms * 1.25) cubic-bezier(0.25, 1, 0.5, 1); } .glass-input-wrap:focus-within .glass-input-text-area::after { background-position: 25% 50%; }
        `}</style>

            {/* Ambient Lights in the new design style */}
            <div className="absolute inset-0 w-full h-full overflow-hidden pointer-events-none">
                <div className="absolute top-[-10%] left-[-10%] w-[50vw] h-[50vw] bg-midnight-light/40 rounded-full mix-blend-screen filter blur-[128px] animate-pulse" />
                <div className="absolute bottom-[-10%] right-[-10%] w-[50vw] h-[50vw] bg-blue-900/10 rounded-full mix-blend-screen filter blur-[128px] animate-pulse delay-700" />
                <div className="absolute top-[20%] right-[10%] w-[40vw] h-[40vw] bg-gold/10 rounded-full mix-blend-screen filter blur-[96px] animate-pulse delay-1000" />
            </div>

            <Confetti ref={confettiRef} manualstart className="fixed top-0 left-0 w-full h-full pointer-events-none z-[999]" />
            <Modal />

            <div className={cn("fixed top-8 left-8 z-20 flex items-center gap-3", "md:left-1/2 md:-translate-x-1/2")}>
                {logo}
                <h1 className="text-sm font-bold text-white tracking-widest uppercase">{brandName}</h1>
            </div>

            <div className={cn("flex w-full flex-1 h-full items-center justify-center relative overflow-hidden")}>
                {/* Replaced GradientBackground with our ambient lights but kept the component wrapper if needed for structure, or used the SVG as a subtle overlay layer */}
                <div className="absolute inset-0 z-0 opacity-40"><GradientBackground /></div>

                <fieldset disabled={modalStatus !== 'closed'} className="relative z-10 flex flex-col items-center gap-8 w-full max-w-[340px] mx-auto p-4 scale-100 sm:scale-110 transition-transform">
                    <AnimatePresence mode="wait">
                        {authStep === "email" && <motion.div key="email-content" initial={{ y: 6, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.3, ease: "easeOut" }} className="w-full flex flex-col items-center gap-4">
                            <BlurFade delay={0.25 * 1} className="w-full"><div className="text-center"><p className="font-serif font-light text-4xl sm:text-5xl md:text-6xl tracking-tight text-white whitespace-nowrap drop-shadow-lg" style={{ fontFamily: 'var(--font-playfair)' }}>Criar Conta</p></div></BlurFade>
                            <BlurFade delay={0.25 * 2}><p className="text-xs font-medium text-white/40 uppercase tracking-widest">Digite seu email para começar</p></BlurFade>
                        </motion.div>}
                        {authStep === "password" && <motion.div key="password-title" initial={{ y: 6, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.3, ease: "easeOut" }} className="w-full flex flex-col items-center text-center gap-4">
                            <BlurFade delay={0} className="w-full"><div className="text-center"><p className="font-serif font-light text-4xl sm:text-5xl tracking-tight text-white whitespace-nowrap drop-shadow-lg" style={{ fontFamily: 'var(--font-playfair)' }}>Sua Senha</p></div></BlurFade>
                            <BlurFade delay={0.25 * 1}><p className="text-xs font-medium text-white/40 uppercase tracking-widest">Mínimo de 6 caracteres</p></BlurFade>
                        </motion.div>}
                        {authStep === "confirmPassword" && <motion.div key="confirm-title" initial={{ y: 6, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.3, ease: "easeOut" }} className="w-full flex flex-col items-center text-center gap-4">
                            <BlurFade delay={0} className="w-full"><div className="text-center"><p className="font-serif font-light text-4xl sm:text-5xl tracking-tight text-white whitespace-nowrap drop-shadow-lg" style={{ fontFamily: 'var(--font-playfair)' }}>Confirme</p></div></BlurFade>
                            <BlurFade delay={0.25 * 1}><p className="text-xs font-medium text-white/40 uppercase tracking-widest">Confirme sua senha para continuar</p></BlurFade>
                        </motion.div>}
                        {authStep === "name" && <motion.div key="name-title" initial={{ y: 6, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.3, ease: "easeOut" }} className="w-full flex flex-col items-center text-center gap-4">
                            <BlurFade delay={0} className="w-full"><div className="text-center"><p className="font-serif font-light text-4xl sm:text-5xl tracking-tight text-white whitespace-nowrap drop-shadow-lg" style={{ fontFamily: 'var(--font-playfair)' }}>Seu Nome</p></div></BlurFade>
                            <BlurFade delay={0.25 * 1}><p className="text-xs font-medium text-white/40 uppercase tracking-widest">Como podemos te chamar?</p></BlurFade>
                        </motion.div>}
                        {authStep === "gender" && <motion.div key="gender-title" initial={{ y: 6, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.3, ease: "easeOut" }} className="w-full flex flex-col items-center text-center gap-4">
                            <BlurFade delay={0} className="w-full"><div className="text-center"><p className="font-serif font-light text-4xl sm:text-5xl tracking-tight text-white whitespace-nowrap drop-shadow-lg" style={{ fontFamily: 'var(--font-playfair)' }}>Olá, {fullName.split(' ')[0]}!</p></div></BlurFade>
                            <BlurFade delay={0.25 * 1}><p className="text-xs font-medium text-white/40 uppercase tracking-widest">Como devemos te tratar?</p></BlurFade>
                        </motion.div>}
                    </AnimatePresence>

                    <form onSubmit={handleFinalSubmit} className="w-[300px] space-y-6">
                        <AnimatePresence>
                            {(authStep === 'email' || authStep === 'password') && <motion.div key="email-password-fields" exit={{ opacity: 0, filter: 'blur(4px)' }} transition={{ duration: 0.3, ease: "easeOut" }} className="w-full space-y-6">
                                <BlurFade delay={authStep === 'email' ? 0.25 * 3 : 0} inView={true} className="w-full">
                                    <div className="relative w-full">
                                        <AnimatePresence>
                                            {authStep === "password" && <motion.div initial={{ y: -10, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ duration: 0.3, delay: 0.4 }} className="absolute -top-6 left-4 z-10"><label className="text-[10px] text-white/50 font-bold uppercase tracking-widest">Email</label></motion.div>}
                                        </AnimatePresence>
                                        <div className="glass-input-wrap w-full"><div className="glass-input">
                                            <span className="glass-input-text-area"></span>
                                            <div className={cn("relative z-10 flex-shrink-0 flex items-center justify-center overflow-hidden transition-all duration-300 ease-in-out", email.length > 20 && authStep === 'email' ? "w-0 px-0" : "w-10 pl-2")}><Mail className="h-5 w-5 text-white/60 flex-shrink-0" /></div>
                                            <input type="email" placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} onKeyDown={handleKeyDown} className={cn("relative z-10 h-full w-0 flex-grow bg-transparent text-white placeholder:text-white/30 focus:outline-none transition-[padding-right] duration-300 ease-in-out delay-300", isEmailValid && authStep === 'email' ? "pr-2" : "pr-0")} />
                                            <div className={cn("relative z-10 flex-shrink-0 overflow-hidden transition-all duration-300 ease-in-out", isEmailValid && authStep === 'email' ? "w-10 pr-1" : "w-0")}><GlassButton type="button" onClick={handleProgressStep} size="icon" aria-label="Continue with email" contentClassName="text-white/80 hover:text-white"><ArrowRight className="w-5 h-5" /></GlassButton></div>
                                        </div></div>
                                    </div>
                                    {authStep === 'email' && (
                                        <motion.div
                                            initial={{ opacity: 0 }}
                                            animate={{ opacity: 1 }}
                                            className="mt-4 flex justify-center w-full"
                                        >
                                            <Link href="/login" className="text-xs text-white/40 hover:text-white/80 transition-colors">
                                                Já tem uma conta? <span className="text-gold hover:underline">Entrar</span>
                                            </Link>
                                        </motion.div>
                                    )}
                                </BlurFade>
                                <AnimatePresence>
                                    {authStep === "password" && <BlurFade key="password-field" className="w-full">
                                        <div className="relative w-full">
                                            <AnimatePresence>
                                                {password.length > 0 && <motion.div initial={{ y: -10, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ duration: 0.3 }} className="absolute -top-6 left-4 z-10"><label className="text-[10px] text-white/50 font-bold uppercase tracking-widest">Senha</label></motion.div>}
                                            </AnimatePresence>
                                            <div className="glass-input-wrap w-full"><div className="glass-input">
                                                <span className="glass-input-text-area"></span>
                                                <div className="relative z-10 flex-shrink-0 flex items-center justify-center w-10 pl-2">
                                                    {isPasswordValid ? <button type="button" aria-label="Toggle password visibility" onClick={() => setShowPassword(!showPassword)} className="text-white/60 hover:text-white transition-colors p-2 rounded-full">{showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}</button> : <Lock className="h-5 w-5 text-white/60 flex-shrink-0" />}
                                                </div>
                                                <input ref={passwordInputRef} type={showPassword ? "text" : "password"} placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} onKeyDown={handleKeyDown} className="relative z-10 h-full w-0 flex-grow bg-transparent text-white placeholder:text-white/30 focus:outline-none" />
                                                <div className={cn("relative z-10 flex-shrink-0 overflow-hidden transition-all duration-300 ease-in-out", isPasswordValid ? "w-10 pr-1" : "w-0")}><GlassButton type="button" onClick={handleProgressStep} size="icon" aria-label="Submit password" contentClassName="text-white/80 hover:text-white"><ArrowRight className="w-5 h-5" /></GlassButton></div>
                                            </div></div>
                                        </div>
                                        <BlurFade inView delay={0.2}><button type="button" onClick={handleGoBack} className="mt-4 flex items-center gap-2 text-xs text-white/40 hover:text-white/80 transition-colors uppercase tracking-widest font-medium"><ArrowLeft className="w-3 h-3" /> Voltar</button></BlurFade>
                                    </BlurFade>}
                                </AnimatePresence>
                            </motion.div>}
                        </AnimatePresence>
                        <AnimatePresence>
                            {authStep === 'confirmPassword' && <BlurFade key="confirm-password-field" className="w-full">
                                <div className="relative w-full">
                                    <AnimatePresence>
                                        {confirmPassword.length > 0 && <motion.div initial={{ y: -10, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ duration: 0.3 }} className="absolute -top-6 left-4 z-10"><label className="text-[10px] text-white/50 font-bold uppercase tracking-widest">Confirme a Senha</label></motion.div>}
                                    </AnimatePresence>
                                    <div className="glass-input-wrap w-[300px]"><div className="glass-input">
                                        <span className="glass-input-text-area"></span>
                                        <div className="relative z-10 flex-shrink-0 flex items-center justify-center w-10 pl-2">
                                            {isConfirmPasswordValid ? <button type="button" aria-label="Toggle confirm password visibility" onClick={() => setShowConfirmPassword(!showConfirmPassword)} className="text-white/60 hover:text-white transition-colors p-2 rounded-full">{showConfirmPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}</button> : <Lock className="h-5 w-5 text-white/60 flex-shrink-0" />}
                                        </div>
                                        <input ref={confirmPasswordInputRef} type={showConfirmPassword ? "text" : "password"} placeholder="••••••••" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} onKeyDown={handleKeyDown} className="relative z-10 h-full w-0 flex-grow bg-transparent text-white placeholder:text-white/30 focus:outline-none" />
                                        <div className={cn("relative z-10 flex-shrink-0 overflow-hidden transition-all duration-300 ease-in-out", isConfirmPasswordValid ? "w-10 pr-1" : "w-0")}><GlassButton type="button" onClick={handleProgressStep} size="icon" aria-label="Continue" contentClassName="text-white/80 hover:text-white"><ArrowRight className="w-5 h-5" /></GlassButton></div>
                                    </div></div>
                                </div>
                                <BlurFade inView delay={0.2}><button type="button" onClick={handleGoBack} className="mt-4 flex items-center gap-2 text-xs text-white/40 hover:text-white/80 transition-colors uppercase tracking-widest font-medium"><ArrowLeft className="w-3 h-3" /> Voltar</button></BlurFade>
                            </BlurFade>}
                        </AnimatePresence>
                        <AnimatePresence>
                            {authStep === 'name' && <BlurFade key="name-field" className="w-full">
                                <div className="relative w-full">
                                    <AnimatePresence>
                                        {fullName.length > 0 && <motion.div initial={{ y: -10, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ duration: 0.3 }} className="absolute -top-6 left-4 z-10"><label className="text-[10px] text-white/50 font-bold uppercase tracking-widest">Seu Nome</label></motion.div>}
                                    </AnimatePresence>
                                    <div className="glass-input-wrap w-[300px]"><div className="glass-input">
                                        <span className="glass-input-text-area"></span>
                                        <div className="relative z-10 flex-shrink-0 flex items-center justify-center w-10 pl-2">
                                            <User className="h-5 w-5 text-white/60 flex-shrink-0" />
                                        </div>
                                        <input ref={nameInputRef} type="text" placeholder="Digite seu nome" value={fullName} onChange={(e) => setFullName(e.target.value)} onKeyDown={handleKeyDown} className="relative z-10 h-full w-0 flex-grow bg-transparent text-white placeholder:text-white/30 focus:outline-none" />
                                        <div className={cn("relative z-10 flex-shrink-0 overflow-hidden transition-all duration-300 ease-in-out", isNameValid ? "w-10 pr-1" : "w-0")}><GlassButton type="button" onClick={handleProgressStep} size="icon" aria-label="Continue" contentClassName="text-white/80 hover:text-white"><ArrowRight className="w-5 h-5" /></GlassButton></div>
                                    </div></div>
                                </div>
                                <BlurFade inView delay={0.2}><button type="button" onClick={handleGoBack} className="mt-4 flex items-center gap-2 text-xs text-white/40 hover:text-white/80 transition-colors uppercase tracking-widest font-medium"><ArrowLeft className="w-3 h-3" /> Voltar</button></BlurFade>
                            </BlurFade>}
                        </AnimatePresence>
                        <AnimatePresence>
                            {authStep === 'gender' && <BlurFade key="gender-field" className="w-full">
                                <div className="flex flex-col items-center gap-4">
                                    <div className="grid grid-cols-3 gap-3 w-full">
                                        <button
                                            type="button"
                                            onClick={() => setGender('male')}
                                            className={cn(
                                                "flex flex-col items-center gap-2 p-4 rounded-2xl border transition-all duration-300",
                                                "backdrop-blur-xl",
                                                gender === 'male'
                                                    ? "bg-gold/20 border-gold/50 shadow-[0_0_20px_-5px_rgba(212,175,55,0.4)]"
                                                    : "bg-white/5 border-white/10 hover:bg-white/10 hover:border-white/20"
                                            )}
                                        >
                                            <UserCircle className={cn("w-8 h-8", gender === 'male' ? "text-gold" : "text-white/60")} />
                                            <span className={cn("text-xs font-medium", gender === 'male' ? "text-gold" : "text-white/60")}>Sr.</span>
                                        </button>
                                        <button
                                            type="button"
                                            onClick={() => setGender('female')}
                                            className={cn(
                                                "flex flex-col items-center gap-2 p-4 rounded-2xl border transition-all duration-300",
                                                "backdrop-blur-xl",
                                                gender === 'female'
                                                    ? "bg-gold/20 border-gold/50 shadow-[0_0_20px_-5px_rgba(212,175,55,0.4)]"
                                                    : "bg-white/5 border-white/10 hover:bg-white/10 hover:border-white/20"
                                            )}
                                        >
                                            <UserCircle className={cn("w-8 h-8", gender === 'female' ? "text-gold" : "text-white/60")} />
                                            <span className={cn("text-xs font-medium", gender === 'female' ? "text-gold" : "text-white/60")}>Sra.</span>
                                        </button>
                                        <button
                                            type="button"
                                            onClick={() => setGender('other')}
                                            className={cn(
                                                "flex flex-col items-center gap-2 p-4 rounded-2xl border transition-all duration-300",
                                                "backdrop-blur-xl",
                                                gender === 'other'
                                                    ? "bg-gold/20 border-gold/50 shadow-[0_0_20px_-5px_rgba(212,175,55,0.4)]"
                                                    : "bg-white/5 border-white/10 hover:bg-white/10 hover:border-white/20"
                                            )}
                                        >
                                            <User className={cn("w-8 h-8", gender === 'other' ? "text-gold" : "text-white/60")} />
                                            <span className={cn("text-xs font-medium", gender === 'other' ? "text-gold" : "text-white/60")}>Outro</span>
                                        </button>
                                    </div>
                                    <div className={cn("transition-all duration-300", gender ? "opacity-100" : "opacity-0 pointer-events-none")}>
                                        <GlassButton type="submit" aria-label="Finalizar cadastro" contentClassName="text-white/80 hover:text-white flex items-center gap-2">
                                            Finalizar Cadastro <ArrowRight className="w-4 h-4" />
                                        </GlassButton>
                                    </div>
                                </div>
                                <BlurFade inView delay={0.2}><button type="button" onClick={handleGoBack} className="mt-4 flex items-center gap-2 text-xs text-white/40 hover:text-white/80 transition-colors uppercase tracking-widest font-medium"><ArrowLeft className="w-3 h-3" /> Voltar</button></BlurFade>
                            </BlurFade>}
                        </AnimatePresence>
                    </form>
                </fieldset>
            </div>
        </div>
    );
};
