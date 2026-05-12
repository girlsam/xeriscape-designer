import { useEffect, useRef, useState } from 'react'
import type { Message } from '../types'

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
    <div style={styles.container}>
      <div style={styles.header}>
        <span style={styles.title}>Xeriscape Designer</span>
      </div>

      <div style={styles.messages}>
        {messages.length === 0 && (
          <p style={styles.empty}>
            Describe your yard — dimensions, existing trees, paths, sun exposure,
            style. Claude will ask clarifying questions and produce a planting plan.
          </p>
        )}
        {messages.map((msg, i) => (
          <div key={i} style={msg.role === 'user' ? styles.userBubble : styles.assistantBubble}>
            {msg.content}
          </div>
        ))}
        {isLoading && (
          <div style={styles.assistantBubble}>
            <span style={styles.typing}>···</span>
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      <form onSubmit={handleSubmit} style={styles.form}>
        <textarea
          style={styles.input}
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
        <button type="submit" style={styles.button} disabled={isLoading || !input.trim()}>
          Send
        </button>
      </form>
    </div>
  )
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    display: 'flex',
    flexDirection: 'column',
    height: '100%',
    borderRight: '1px solid #e2ddd8',
    background: '#fff',
  },
  header: {
    padding: '16px 20px',
    borderBottom: '1px solid #e2ddd8',
    flexShrink: 0,
  },
  title: {
    fontWeight: 600,
    fontSize: '14px',
    letterSpacing: '0.02em',
    textTransform: 'uppercase',
    color: '#6b6b6b',
  },
  messages: {
    flex: 1,
    overflowY: 'auto',
    padding: '20px',
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
  },
  empty: {
    color: '#999',
    fontSize: '14px',
    lineHeight: '1.6',
    marginTop: '8px',
  },
  userBubble: {
    alignSelf: 'flex-end',
    background: '#2d6a4f',
    color: '#fff',
    borderRadius: '16px 16px 4px 16px',
    padding: '10px 14px',
    maxWidth: '80%',
    lineHeight: '1.5',
    whiteSpace: 'pre-wrap',
  },
  assistantBubble: {
    alignSelf: 'flex-start',
    background: '#f0ece8',
    color: '#1a1a1a',
    borderRadius: '16px 16px 16px 4px',
    padding: '10px 14px',
    maxWidth: '85%',
    lineHeight: '1.5',
    whiteSpace: 'pre-wrap',
  },
  typing: {
    color: '#999',
    letterSpacing: '2px',
  },
  form: {
    padding: '16px 20px',
    borderTop: '1px solid #e2ddd8',
    display: 'flex',
    gap: '10px',
    flexShrink: 0,
    alignItems: 'flex-end',
  },
  input: {
    flex: 1,
    resize: 'none',
    border: '1px solid #e2ddd8',
    borderRadius: '8px',
    padding: '10px 12px',
    fontFamily: 'inherit',
    fontSize: '14px',
    lineHeight: '1.5',
    outline: 'none',
    background: '#fafaf9',
  },
  button: {
    padding: '10px 18px',
    background: '#2d6a4f',
    color: '#fff',
    border: 'none',
    borderRadius: '8px',
    fontFamily: 'inherit',
    fontSize: '14px',
    fontWeight: 500,
    cursor: 'pointer',
    flexShrink: 0,
  },
}
