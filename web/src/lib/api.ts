import type { Design, Message, RecommendationResponse } from '../types'

const API_BASE = import.meta.env.VITE_API_URL ?? 'http://localhost:3000'

export async function getRecommendation(
  messages: Message[],
  currentDesign: Design | null
): Promise<RecommendationResponse> {
  const res = await fetch(`${API_BASE}/api/v1/recommendations`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ messages, current_design: currentDesign }),
  })

  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    throw new Error(body.error ?? `Request failed: ${res.status}`)
  }

  return res.json()
}
