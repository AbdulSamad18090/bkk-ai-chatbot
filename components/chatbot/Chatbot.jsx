"use client";
import React, { useEffect, useRef, useState } from "react";
import { MotionConfig, motion } from "framer-motion";
import {
  Search,
  Send,
  User,
  MessageCircle,
  Settings,
  Menu,
  X,
  Plus,
  LogOut,
  PanelLeftClose,
  PanelRightClose,
  Power,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import Image from "next/image";
import { ModeToggle } from "./ModeToggle";

export default function ChatbotUI() {
  const [conversations, setConversations] = useState([
    {
      id: 1,
      title: "Welcome Chat",
      last: "How can I help you today?",
      unread: 0,
    },
    { id: 2, title: "Project Ideas", last: "Let's brainstorm...", unread: 2 },
  ]);

  const [activeConvId, setActiveConvId] = useState(1);
  const [messagesByConv, setMessagesByConv] = useState({
    1: [
      {
        id: "m1",
        role: "assistant",
        text: "Hi — I'm your assistant. Ask me anything!",
        time: "10:00",
      },
    ],
    2: [
      {
        id: "m2",
        role: "assistant",
        text: "Tell me what kind of project you want.",
        time: "09:55",
      },
      {
        id: "m3",
        role: "user",
        text: "A portfolio site with animations.",
        time: "09:56",
      },
    ],
  });

  const [input, setInput] = useState("");
  const [isThinking, setIsThinking] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const inputRef = useRef(null);
  const messagesEndRef = useRef(null);

  const activeMessages = messagesByConv[activeConvId] || [];

  useEffect(() => {
    // scroll to bottom on messages change
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [activeMessages, isThinking]);

  function sendMessage() {
    if (!input.trim()) return;
    const text = input.trim();
    const id = Math.random().toString(36).slice(2, 9);
    const message = {
      id,
      role: "user",
      text,
      time: new Date().toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
      }),
    };

    setMessagesByConv((prev) => {
      const copy = { ...prev };
      copy[activeConvId] = [...(copy[activeConvId] || []), message];
      return copy;
    });

    setInput("");
    setIsThinking(true);

    // fake assistant reply streaming
    setTimeout(() => {
      const assistId = Math.random().toString(36).slice(2, 9);
      const reply = {
        id: assistId,
        role: "assistant",
        text: `Here's a helpful reply to: ${text}`,
        time: new Date().toLocaleTimeString([], {
          hour: "2-digit",
          minute: "2-digit",
        }),
      };
      setMessagesByConv((prev) => {
        const copy = { ...prev };
        copy[activeConvId] = [...(copy[activeConvId] || []), reply];
        return copy;
      });
      setIsThinking(false);
    }, 1000 + Math.random() * 1200);
  }

  function newConversation() {
    const id = Date.now();
    const title = `New chat ${conversations.length + 1}`;
    setConversations((c) => [{ id, title, last: "", unread: 0 }, ...c]);
    setMessagesByConv((m) => ({ ...m, [id]: [] }));
    setActiveConvId(id);
    setTimeout(() => inputRef.current?.focus(), 100);
  }

  function renderBubble(m) {
    const isUser = m.role === "user";
    return (
      <div
        key={m.id}
        className={`flex ${isUser ? "justify-end" : "justify-start"} py-1`}
      >
        <div
          className={`max-w-[78%] break-words rounded-2xl p-3 shadow-sm ${
            isUser
              ? "bg-primary text-primary-foreground"
              : "bg-card text-card-foreground border"
          }`}
        >
          <div className="text-sm whitespace-pre-wrap">{m.text}</div>
          <div className="text-[11px] opacity-60 text-right mt-1">{m.time}</div>
        </div>
      </div>
    );
  }

  return (
    <MotionConfig>
      <div className="h-screen w-screen bg-background flex">
        {/* Sidebar */}
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

            {/* Conversations list - will now expand */}
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

        {/* Main chat */}
        <main className="flex-1 flex flex-col min-w-0">
          {/* Top bar */}
          <header className="flex items-center justify-between p-4 border-b border-border bg-card">
            <div className="flex items-center gap-3">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setSidebarOpen(!sidebarOpen)}
              >
                {sidebarOpen ? (
                  <PanelLeftClose className="w-4 h-4" />
                ) : (
                  <PanelRightClose className="w-4 h-4" />
                )}
              </Button>

              <div className="w-10 h-10 rounded-md bg-muted flex border items-center justify-center font-bold">
                A
              </div>
              <div>
                <div className="font-semibold text-foreground">
                  {conversations.find((c) => c.id === activeConvId)?.title ??
                    "New chat"}
                </div>
                <div className="text-xs text-muted-foreground">
                  {activeMessages.length} messages
                </div>
              </div>
            </div>

            <div className="flex items-center gap-3">
              {/* Theme Toggler */}
              <ModeToggle />
            </div>
          </header>

          {/* Messages area */}
          <div className="flex-1 overflow-auto p-6 bg-gradient-to-b from-muted/50 to-background">
            <div className="mx-auto w-full max-w-3xl">
              <div className="space-y-3">
                {activeMessages.map(renderBubble)}

                {isThinking && (
                  <div className="flex justify-start py-1">
                    <div className="max-w-[78%] rounded-2xl p-3 shadow-sm bg-card text-card-foreground border">
                      <TypingDots />
                    </div>
                  </div>
                )}

                <div ref={messagesEndRef} />
              </div>
            </div>
          </div>

          {/* Composer */}
          <div className="p-4 border-t border-border bg-card">
            <div className="max-w-3xl mx-auto flex items-center gap-3">
              <Input
                ref={inputRef}
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && !e.shiftKey) {
                    e.preventDefault();
                    sendMessage();
                  }
                }}
                placeholder="Send a message... (Press Enter to send)"
                className="flex-1"
              />
              <Button onClick={sendMessage}>
                <Send className="w-4 h-4 mr-2" /> Send
              </Button>
            </div>
          </div>
        </main>
      </div>
    </MotionConfig>
  );
}

function TypingDots() {
  return (
    <div className="flex items-center gap-1">
      <motion.span
        animate={{ y: [0, -6, 0] }}
        transition={{ repeat: Infinity, duration: 0.6 }}
        className="w-2 h-2 rounded-full bg-muted-foreground"
      />
      <motion.span
        animate={{ y: [0, -6, 0] }}
        transition={{ repeat: Infinity, duration: 0.6, delay: 0.1 }}
        className="w-2 h-2 rounded-full bg-muted-foreground"
      />
      <motion.span
        animate={{ y: [0, -6, 0] }}
        transition={{ repeat: Infinity, duration: 0.6, delay: 0.2 }}
        className="w-2 h-2 rounded-full bg-muted-foreground"
      />
    </div>
  );
}
