import React, { useState, useRef, useEffect, useMemo } from 'react';
import { Home, MessageCircle, CreditCard, User } from 'lucide-react';
import { cn } from "@/lib/utils";

type IconComponentType = React.ElementType<{ className?: string }>;

export interface InteractiveMenuItem {
    label: string;
    icon: IconComponentType;
    action?: () => void;
}

export interface InteractiveMenuProps {
    items?: InteractiveMenuItem[];
    accentColor?: string;
    activeIndex?: number;
    onItemClick?: (index: number) => void;
}

const defaultItems: InteractiveMenuItem[] = [
    { label: 'Início', icon: Home },
    { label: 'Chat', icon: MessageCircle },
    { label: 'Cartão', icon: CreditCard },
    { label: 'Perfil', icon: User },
];

const InteractiveMenu: React.FC<InteractiveMenuProps> = ({
    items,
    accentColor = '#B4975A',
    activeIndex: controlledActiveIndex,
    onItemClick,
}) => {
    const finalItems = useMemo(() => {
        const isValid = items && Array.isArray(items) && items.length >= 2 && items.length <= 5;
        if (!isValid) {
            return defaultItems;
        }
        return items;
    }, [items]);

    const [internalActiveIndex, setInternalActiveIndex] = useState(0);
    const activeIndex = controlledActiveIndex ?? internalActiveIndex;

    useEffect(() => {
        if (activeIndex >= finalItems.length) {
            setInternalActiveIndex(0);
        }
    }, [finalItems, activeIndex]);

    const textRefs = useRef<(HTMLElement | null)[]>([]);
    const itemRefs = useRef<(HTMLButtonElement | null)[]>([]);

    useEffect(() => {
        const setLineWidth = () => {
            const activeItemElement = itemRefs.current[activeIndex];
            const activeTextElement = textRefs.current[activeIndex];
            if (activeItemElement && activeTextElement) {
                const textWidth = activeTextElement.offsetWidth;
                activeItemElement.style.setProperty('--lineWidth', `${textWidth}px`);
            }
        };

        setLineWidth();
        window.addEventListener('resize', setLineWidth);
        return () => {
            window.removeEventListener('resize', setLineWidth);
        };
    }, [activeIndex, finalItems]);

    const handleItemClick = (index: number) => {
        if (onItemClick) {
            onItemClick(index);
        } else {
            setInternalActiveIndex(index);
        }
        finalItems[index]?.action?.();
    };

    const navStyle = useMemo(() => {
        return { '--dock-accent-color': accentColor } as React.CSSProperties;
    }, [accentColor]);

    return (
        <nav
            className="fixed bottom-0 left-0 right-0 flex justify-around items-center px-4 py-3 z-50 mobile-dock pb-[calc(0.25rem+env(safe-area-inset-bottom))]"
            role="navigation"
            style={{
                ...navStyle,
                backgroundColor: 'rgba(255, 255, 255, 0.95)',
                backdropFilter: 'blur(10px)',
                borderTop: '1px solid rgba(229, 231, 235, 0.8)',
                boxShadow: '0 -20px 40px rgba(0, 0, 0, 0.08)',
            }}
        >
            {finalItems.map((item, index) => {
                const isActive = index === activeIndex;
                const IconComponent = item.icon;

                return (
                    <button
                        key={item.label}
                        className={cn(
                            "flex flex-col items-center gap-1 p-2 rounded-xl transition-all duration-300 relative group",
                            isActive ? "text-midnight" : "text-gray-400 hover:bg-black/5"
                        )}
                        onClick={() => handleItemClick(index)}
                        ref={(el) => { itemRefs.current[index] = el; }}
                        style={{ '--lineWidth': '0px' } as React.CSSProperties}
                    >
                        {/* Active Indicator Line (Top) */}
                        {isActive && (
                            <span
                                className="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-1 bg-gold rounded-full"
                                style={{ width: 'var(--lineWidth, 32px)' }}
                            />
                        )}

                        <div className={cn(
                            "transition-transform duration-300",
                            isActive ? "-translate-y-0.5" : ""
                        )}>
                            <IconComponent className="w-5 h-5" />
                        </div>
                        <span
                            className={cn(
                                "text-[11px] font-semibold whitespace-nowrap transition-all duration-300",
                                isActive ? "font-bold" : ""
                            )}
                            ref={(el) => { textRefs.current[index] = el; }}
                        >
                            {item.label}
                        </span>
                    </button>
                );
            })}
        </nav>
    );
};

export { InteractiveMenu };