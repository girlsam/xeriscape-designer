export interface Message {
  role: 'user' | 'assistant'
  content: string
}

export interface Position {
  x: number
  y: number
}

export interface Plant {
  letter: string
  common_name: string
  scientific_name?: string
  plant_type: string
  color: string
  mature_spread_ft: number
  quantity: number
  positions: Position[]
}

export interface ExistingFeature {
  type: string
  label: string
  x: number
  y: number
  width?: number
  height?: number
  radius_ft?: number
}

export interface Design {
  yard: {
    boundary: Position[]
    unit: string
    existing_features?: ExistingFeature[]
  }
  plants: Plant[]
}

export interface LegendItem {
  letter: string
  common_name: string
  scientific_name?: string
  plant_type: string
  color: string
  mature_spread_ft: number
  mature_height_ft: number
  quantity: number
}

export interface RecommendationResponse {
  message: string
  design?: Design
  svg?: string
  legend?: LegendItem[]
}
