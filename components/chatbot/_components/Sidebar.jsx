"use client";
import React from "react";
import { motion } from "framer-motion";
import { Search, Plus, Power } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import Image from "next/image";

export default function Sidebar({
  sidebarOpen,
  conversations,
  activeConvId,
  setActiveConvId,
  newConversation,
}) {
  return (
    <motion.aside
      animate={{ width: sidebarOpen ? 320 : 0 }}
      transition={{ type: "spring", damping: 30, stiffness: 220 }}
      className="bg-card border-r border-border flex flex-col overflow-hidden h-full"
    >
      <div className="p-4 flex flex-col gap-4 flex-1 min-w-[320px]">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Image
              src="/images/bkk-logo.png"
              alt="Bakhabar Kissan"
              width={60}
              height={60}
            />
            <h2 className="text-lg font-semibold text-foreground">
              Bakhabar Kissan
            </h2>
          </div>
          <Button size="icon" onClick={newConversation}>
            <Plus />
          </Button>
        </div>

        {/* Search */}
        <div className="relative">
          <Input placeholder="Search chats" className="pl-10" />
          <Search className="absolute left-3 top-3 w-4 h-4 text-muted-foreground" />
        </div>

        {/* Conversations list */}
        <div className="flex-1 overflow-auto">
          <ul className="space-y-2">
            {conversations.map((c) => (
              <li
                key={c.id}
                onClick={() => setActiveConvId(c.id)}
                className={`cursor-pointer p-3 rounded-lg hover:bg-accent hover:text-accent-foreground flex items-center justify-between transition-colors ${
                  c.id === activeConvId
                    ? "bg-accent text-accent-foreground border border-border"
                    : ""
                }`}
              >
                <div>
                  <div className="font-medium">{c.title}</div>
                  <div className="text-sm text-muted-foreground truncate max-w-[200px]">
                    {c.last}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {c.unread > 0 && (
                    <Badge variant="secondary">{c.unread}</Badge>
                  )}
                  <div className="text-xs text-muted-foreground">&gt;</div>
                </div>
              </li>
            ))}
          </ul>
        </div>

        {/* Footer */}
        <div className="pt-3 border-t border-border flex items-center justify-between gap-3">
          <div>
            <h1 className="font-semibold">Abdul Samad</h1>
            <p className="text-xs text-muted-foreground">
              abdulsamad18090@gmail.com
            </p>
          </div>
          <Button size="icon" variant="ghost">
            <Power />
          </Button>
        </div>
      </div>
    </motion.aside>
  );
}