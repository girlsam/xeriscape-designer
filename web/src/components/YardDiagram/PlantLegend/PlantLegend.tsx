import type { ReactNode } from 'react'
import type { LegendItem } from '../../../types'
import { textColorForBg } from '../../../lib/color'
import styles from './PlantLegend.module.css'

interface Column {
  key: string
  header: string
  render: (item: LegendItem) => ReactNode
}

const COLUMNS: Column[] = [
  {
    key: 'badge',
    header: '',
    render: (item) => (
      <span
        className={styles.letterBadge}
        style={{ background: item.color, color: textColorForBg(item.color) }}
      >
        {item.letter}
      </span>
    ),
  },
  {
    key: 'plant',
    header: 'Plant',
    render: (item) => (
      <a
        href={`https://www.google.com/search?q=${encodeURIComponent([item.common_name, item.scientific_name].filter(Boolean).join(' '))}`}
        target="_blank"
        rel="noopener noreferrer"
        className={styles.plantLink}
      >
        <strong className={styles.plantName}>{item.common_name}</strong>
        {item.scientific_name && (
          <em className={styles.scientificName}>{item.scientific_name}</em>
        )}
      </a>
    ),
  },
  {
    key: 'type',
    header: 'Type',
    render: (item) => item.plant_type,
  },
  {
    key: 'height',
    header: 'Height',
    render: (item) => `${item.mature_height_ft} ft`,
  },
  {
    key: 'spread',
    header: 'Spread',
    render: (item) => `${item.mature_spread_ft} ft`,
  },
  {
    key: 'qty',
    header: 'Qty',
    render: (item) => item.quantity,
  },
]

export function PlantLegend({ items }: { items: LegendItem[] }) {
  return (
    <section className={styles.legend}>
      <h2 className={styles.legendTitle}>Plant Legend</h2>
      <table className={styles.table}>
        <thead>
          <tr>
            {COLUMNS.map(col => (
              <th key={col.key} className={styles.th}>{col.header}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {items.map(item => (
            <tr key={item.letter}>
              {COLUMNS.map(col => (
                <td key={col.key} className={styles.td}>{col.render(item)}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  )
}
