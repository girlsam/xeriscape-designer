import { useState } from 'react'
import { Chat } from './components/Chat'
import { YardDiagram } from './components/YardDiagram'
import { getRecommendation } from './lib/api'
import type { Design, LegendItem, Message } from './types'
import styles from './App.module.css'

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
    <div className={styles.layout}>
      <div className={styles.chatPane}>
        <Chat messages={messages} isLoading={isLoading} onSend={handleSend} />
        {error && <div className={styles.error}>{error}</div>}
      </div>
      <div className={styles.diagramPane}>
        <YardDiagram svg={svg} design={currentDesign} legend={legend} />
      </div>
    </div>
  )
}
