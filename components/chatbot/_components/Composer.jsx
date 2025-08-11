import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Send } from 'lucide-react';
import React from 'react'

const Composer = ({ inputRef, input, setInput, sendMessage }) => {
  return (
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
  )
}

export default Composer
