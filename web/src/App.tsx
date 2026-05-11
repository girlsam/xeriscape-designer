import { useState } from 'react'
import { Chat } from './components/Chat'
import { YardDiagram } from './components/YardDiagram'
import { getRecommendation } from './lib/api'
import type { Design, LegendItem, Message } from './types'

export default function App() {
  const [messages, setMessages] = useState<Message[]>([])
  const [currentDesign, setCurrentDesign] = useState<Design | null>(null)
  const [svg, setSvg] = useState<string | null>(null)
  const [legend, setLegend] = useState<LegendItem[] | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleSend(content: string) {
    const userMessage: Message = { role: 'user', content }
    const nextMessages = [...messages, userMessage]

    setMessages(nextMessages)
    setIsLoading(true)
    setError(null)

    try {
      const res = await getRecommendation(nextMessages, currentDesign)

      setMessages([...nextMessages, { role: 'assistant', content: res.message }])

      if (res.design) setCurrentDesign(res.design)
      if (res.svg) setSvg(res.svg)
      if (res.legend) setLegend(res.legend)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div style={styles.layout}>
      <div style={styles.chatPane}>
        <Chat messages={messages} isLoading={isLoading} onSend={handleSend} />
        {error && <div style={styles.error}>{error}</div>}
      </div>
      <div style={styles.diagramPane}>
        <YardDiagram svg={svg} design={currentDesign} legend={legend} />
      </div>
    </div>
  )
}

const styles: Record<string, React.CSSProperties> = {
  layout: {
    display: 'grid',
    gridTemplateColumns: '380px 1fr',
    height: '100vh',
    overflow: 'hidden',
  },
  chatPane: {
    position: 'relative',
    display: 'flex',
    flexDirection: 'column',
    overflow: 'hidden',
  },
  diagramPane: {
    overflow: 'hidden',
    background: '#f9f7f4',
  },
  error: {
    position: 'absolute',
    bottom: '80px',
    left: '12px',
    right: '12px',
    background: '#fee2e2',
    color: '#991b1b',
    padding: '10px 14px',
    borderRadius: '8px',
    fontSize: '13px',
  },
}
