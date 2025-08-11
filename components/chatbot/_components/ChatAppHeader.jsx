import React from "react";
import { ModeToggle } from "../ModeToggle";
import { Button } from "@/components/ui/button";
import { PanelLeftClose, PanelRightClose } from "lucide-react";

const ChatAppHeader = ({
  sidebarOpen,
  setSidebarOpen,
  conversations,
  activeConvId,
  activeMessages,
}) => {
  return (
    <header className="flex items-center justify-between p-4 border-b border-border bg-card">
      <div className="flex items-center gap-3">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => setSidebarOpen(!sidebarOpen)}
        >
          {sidebarOpen ? <PanelLeftClose /> : <PanelRightClose />}
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
  );
};

export default ChatAppHeader;
