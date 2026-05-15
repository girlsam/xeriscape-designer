import { useEffect, useRef, useState } from 'react'
import type { Message } from '../types'
import styles from './Chat.module.css'

interface Props {
  messages: Message[]
  isLoading: boolean
  onSend: (content: string) => void
}

export function Chat({ messages, isLoading, onSend }: Props) {
  const [input, setInput] = useState('')
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, isLoading])

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    const trimmed = input.trim()
    if (!trimmed || isLoading) return
    onSend(trimmed)
    setInput('')
  }

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <span className={styles.title}>Xeriscape Designer</span>
      </div>

      <div className={styles.messages}>
        {messages.length === 0 && (
          <p className={styles.empty}>
            Describe your yard — dimensions, existing trees, paths, sun exposure,
            style. Claude will ask clarifying questions and produce a planting plan.
          </p>
        )}
        {messages.map((msg, i) => (
          <div key={i} className={msg.role === 'user' ? styles.userBubble : styles.assistantBubble}>
            {msg.content}
          </div>
        ))}
        {isLoading && (
          <div className={styles.assistantBubble}>
            <span className={styles.typing}>···</span>
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      <form onSubmit={handleSubmit} className={styles.form}>
        <textarea
          className={styles.input}
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault()
              handleSubmit(e)
            }
          }}
          placeholder="Describe your yard..."
          rows={3}
          disabled={isLoading}
        />
        <button type="submit" className={styles.button} disabled={isLoading || !input.trim()}>
          Send
        </button>
      </form>
    </div>
  )
}
