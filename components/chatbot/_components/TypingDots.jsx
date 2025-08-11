import { motion } from "framer-motion";

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

export default TypingDots;
