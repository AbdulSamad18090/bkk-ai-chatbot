"use client";
import React, { useEffect, useRef, useState } from "react";
import { MotionConfig, motion } from "framer-motion";
import { Send, PanelLeftClose, PanelRightClose } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ModeToggle } from "./ModeToggle";
import Sidebar from "./_components/Sidebar";
import TypingDots from "./_components/TypingDots";
import ChatAppHeader from "./_components/ChatAppHeader";
import Composer from "./_components/Composer";

export default function MainChatbot() {
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
        <Sidebar
          sidebarOpen={sidebarOpen}
          conversations={conversations}
          activeConvId={activeConvId}
          setActiveConvId={setActiveConvId}
          newConversation={newConversation}
        />

        {/* Main chat */}
        <main className="flex-1 flex flex-col min-w-0">
          {/* Top bar */}
          <ChatAppHeader
            sidebarOpen={sidebarOpen}
            setSidebarOpen={setSidebarOpen}
            conversations={conversations}
            activeConvId={activeConvId}
            activeMessages={activeMessages}
          />

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
          <Composer
            inputRef={inputRef}
            input={input}
            setInput={setInput}
            sendMessage={sendMessage}
          />
        </main>
      </div>
    </MotionConfig>
  );
}
