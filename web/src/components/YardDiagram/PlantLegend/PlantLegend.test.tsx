import { render, screen } from '@testing-library/react'

import { PlantLegend } from './PlantLegend'
import type { LegendItem } from '../../../types'

const item: LegendItem = {
  letter: 'A',
  common_name: 'Blue Grama',
  scientific_name: 'Bouteloua gracilis',
  plant_type: 'Grass',
  color: '#4a7c59',
  mature_height_ft: 2,
  mature_spread_ft: 3,
  quantity: 5,
}

describe('PlantLegend', () => {
  it('shows a row for each plant', () => {
    const items = [item, { ...item, letter: 'B', common_name: 'Desert Willow' }]
    
    render(<PlantLegend items={items} />)
    
    expect(screen.getAllByRole('row')).toHaveLength(items.length + 1) // +1 for header
  })

  it('hides scientific name when not provided', () => {
    render(<PlantLegend items={[{ ...item, scientific_name: undefined }]} />)
    
    expect(screen.queryByText('Bouteloua gracilis')).not.toBeInTheDocument()
  })

  it('shows plant dimensions and quantity', () => {
    render(<PlantLegend items={[item]} />)
    
    expect(screen.getByText('Grass')).toBeInTheDocument()
    expect(screen.getByText('2 ft')).toBeInTheDocument()
    expect(screen.getByText('3 ft')).toBeInTheDocument()
    expect(screen.getByText('5')).toBeInTheDocument()
  })

  it('links plant name to a Google search', () => {
    render(<PlantLegend items={[item]} />)
    
    const link = screen.getByRole('link', { name: /Blue Grama/ })
    
    expect(link).toHaveAttribute('href', expect.stringContaining('google.com/search'))
    expect(link).toHaveAttribute('href', expect.stringContaining(encodeURIComponent('Blue Grama')))
  })

  it('opens plant search in a new tab', () => {
    render(<PlantLegend items={[item]} />)
    
    const link = screen.getByRole('link', { name: /Blue Grama/ })
    
    expect(link).toHaveAttribute('target', '_blank')
    expect(link).toHaveAttribute('rel', 'noopener noreferrer')
  })
})
