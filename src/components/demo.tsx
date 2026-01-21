"use client";

import { useState } from "react";
import { AnimatedAIChat } from "@/components/ui/animated-ai-chat";
import { HomeDashboard } from "@/components/ui/home-dashboard";
import { CardsTab } from "@/components/ui/cards-tab";
import { ProfileTab } from "@/components/ui/profile-tab";
import { InteractiveMenu } from "@/components/ui/mobile-dock";
import { Home, MessageCircle, CreditCard, User } from "lucide-react";

type TabType = "home" | "chat" | "cards" | "profile";

export function Demo() {
    const [activeTab, setActiveTab] = useState<TabType>("home");

    const handleTabChange = (index: number) => {
        const tabs: TabType[] = ["home", "chat", "cards", "profile"];
        setActiveTab(tabs[index]);
    };

    const getActiveIndex = () => {
        const tabs: TabType[] = ["home", "chat", "cards", "profile"];
        return tabs.indexOf(activeTab);
    };

    const dockItems = [
        { label: 'Início', icon: Home },
        { label: 'Chat', icon: MessageCircle },
        { label: 'Cartão', icon: CreditCard },
        { label: 'Perfil', icon: User },
    ];

    return (
        <div className="flex flex-col w-screen h-screen h-[100dvh] overflow-hidden bg-background">
            {/* Tab Content */}
            <div className="flex-1 overflow-hidden">
                {activeTab === "home" && (
                    <HomeDashboard
                        onNavigateToChat={() => setActiveTab("chat")}
                        onNavigateToCards={() => setActiveTab("cards")}
                        onNavigateToProfile={() => setActiveTab("profile")}
                    />
                )}
                {activeTab === "chat" && (
                    <AnimatedAIChat />
                )}
                {activeTab === "cards" && (
                    <CardsTab />
                )}
                {activeTab === "profile" && (
                    <ProfileTab />
                )}
            </div>

            {/* Bottom Dock - Always visible */}
            <div className="shrink-0">
                <InteractiveMenu
                    items={dockItems}
                    activeIndex={getActiveIndex()}
                    onItemClick={handleTabChange}
                    accentColor="#B4975A"
                />
            </div>
        </div>
    );
}
