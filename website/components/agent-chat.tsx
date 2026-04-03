"use client"

import { useEffect, useState, useRef } from "react"

interface ChatMessage {
  role: "user" | "agent"
  content: string
  typing?: boolean
  delay: number
}

const conversation: ChatMessage[] = [
  {
    role: "user",
    content:
      "heres all the screenshots\n\n| Screenshot | Fetch |\n|------------|-------|\n| shot-1 | `curl -s -o /tmp/shot-A1B2C3D4.png ...` |\n| shot-2 | `curl -s -o /tmp/shot-E5F6G7H8.png ...` |\n| shot-3 | `curl -s -o /tmp/shot-I9J0K1L2.png ...` |",
    delay: 3000,
  },
  {
    role: "agent",
    content: "Fetching all three.",
    typing: true,
    delay: 2000,
  },
  {
    role: "agent",
    content:
      "$ curl -s -o /tmp/shot-A1B2C3D4.png ...\n$ curl -s -o /tmp/shot-E5F6G7H8.png ...\n$ curl -s -o /tmp/shot-I9J0K1L2.png ...",
    delay: 2500,
  },
  {
    role: "agent",
    content: "Got them. Fixing all three now.",
    typing: true,
    delay: 3000,
  },
  {
    role: "user",
    content: "can you still see those screenshots?",
    delay: 3000,
  },
  {
    role: "agent",
    content: "No — they return 410 Gone. They only existed in memory.",
    typing: true,
    delay: 3500,
  },
]

export function AgentChat() {
  const [visibleMessages, setVisibleMessages] = useState<number>(0)
  const [isTyping, setIsTyping] = useState(false)
  const scrollRef = useRef<HTMLDivElement>(null)
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    function showNext(index: number) {
      if (index >= conversation.length) {
        // Pause then restart
        timeoutRef.current = setTimeout(() => {
          setVisibleMessages(0)
          setIsTyping(false)
          timeoutRef.current = setTimeout(() => showNext(0), 1000)
        }, 4000)
        return
      }

      const msg = conversation[index]

      if (msg.typing && msg.role === "agent") {
        setIsTyping(true)
        timeoutRef.current = setTimeout(() => {
          setIsTyping(false)
          setVisibleMessages(index + 1)
          timeoutRef.current = setTimeout(() => showNext(index + 1), msg.delay)
        }, 1800)
      } else {
        setVisibleMessages(index + 1)
        timeoutRef.current = setTimeout(() => showNext(index + 1), msg.delay)
      }
    }

    timeoutRef.current = setTimeout(() => showNext(0), 1500)

    return () => {
      if (timeoutRef.current) clearTimeout(timeoutRef.current)
    }
  }, [])

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [visibleMessages, isTyping])

  const displayed = conversation.slice(0, visibleMessages)

  return (
    <div className="overflow-hidden rounded-lg border border-border/50 bg-zinc-950">
      {/* Title bar */}
      <div className="flex items-center gap-2 border-b border-border/30 px-4 py-2.5">
        <div className="flex gap-1.5">
          <div className="size-2.5 rounded-full bg-zinc-700" />
          <div className="size-2.5 rounded-full bg-zinc-700" />
          <div className="size-2.5 rounded-full bg-zinc-700" />
        </div>
        <span className="ml-2 text-[11px] text-zinc-500">
          claude-code — shots-for-agents
        </span>
      </div>

      {/* Chat area */}
      <div
        ref={scrollRef}
        className="scrollbar-none flex h-[360px] flex-col gap-3 overflow-y-auto p-5"
        style={{ scrollbarWidth: "none" }}
      >
        {displayed.map((msg, i) => (
          <ChatBubble key={`${i}-${visibleMessages}`} message={msg} />
        ))}

        {isTyping && (
          <div className="flex items-center gap-1.5 px-1">
            <span className="text-[11px] text-zinc-500">
              Claude is thinking
            </span>
            <span className="inline-flex gap-0.5">
              <span className="size-1 animate-bounce rounded-full bg-zinc-500 [animation-delay:0ms]" />
              <span className="size-1 animate-bounce rounded-full bg-zinc-500 [animation-delay:150ms]" />
              <span className="size-1 animate-bounce rounded-full bg-zinc-500 [animation-delay:300ms]" />
            </span>
          </div>
        )}
      </div>
    </div>
  )
}

function ChatBubble({ message }: { message: ChatMessage }) {
  const isUser = message.role === "user"
  const hasTable = message.content.includes("|--")
  const isCommand =
    message.content.startsWith("curl ") || message.content.startsWith("$ curl")

  function renderContent() {
    if (hasTable) {
      // Split into text part and table part
      const parts = message.content.split("\n\n")
      const textPart = parts[0].includes("|--") ? null : parts[0]
      const tablePart = parts.find((p) => p.includes("|--"))
        ? parts.filter((p) => p.includes("|") || p.includes("|--")).join("\n")
        : null

      return (
        <>
          {textPart && <p className="mb-2">{textPart}</p>}
          {tablePart && (
            <pre className="overflow-x-auto text-[11px] whitespace-pre text-zinc-400">
              {message.content.slice(message.content.indexOf("|"))}
            </pre>
          )}
        </>
      )
    }
    if (isCommand) {
      return <code className="text-emerald-400">{message.content}</code>
    }
    return message.content
  }

  return (
    <div
      className={`flex flex-col gap-1 ${isUser ? "items-end" : "items-start"}`}
    >
      <span className="px-1 text-[10px] font-medium tracking-wider text-zinc-600 uppercase">
        {isUser ? "You" : "Claude Code"}
      </span>
      <div
        className={`max-w-[85%] rounded-lg px-3 py-2 text-[13px] leading-relaxed ${
          isUser
            ? "bg-zinc-800 text-zinc-200"
            : "border border-border/30 bg-zinc-900/80 text-zinc-300"
        } ${isCommand ? "font-mono text-[12px]" : ""}`}
      >
        {renderContent()}
      </div>
    </div>
  )
}
