import type { Design, LegendItem } from '../types'
import { textColorForBg } from '../lib/color'
import styles from './YardDiagram.module.css'

interface Props {
  svg: string | null
  design: Design | null
  legend: LegendItem[] | null
}

export function YardDiagram({ svg, design, legend }: Props) {
  if (!svg || !design) {
    return (
      <div className={styles.empty}>
        <p className={styles.emptyText}>
          Your yard plan will appear here once Claude has enough information to produce a design.
        </p>
      </div>
    )
  }

  return (
    <div className={styles.container}>
      <div
        className={styles.svgWrapper}
        dangerouslySetInnerHTML={{ __html: svg }}
      />
      {legend && legend.length > 0 && (
        <div className={styles.legend}>
          <h3 className={styles.legendTitle}>Plant Legend</h3>
          <table className={styles.table}>
            <thead>
              <tr>
                <th className={styles.th}></th>
                <th className={styles.th}>Plant</th>
                <th className={styles.th}>Type</th>
                <th className={styles.th}>Height</th>
                <th className={styles.th}>Spread</th>
                <th className={styles.th}>Qty</th>
              </tr>
            </thead>
            <tbody>
              {legend.map(item => (
                <tr key={item.letter}>
                  <td className={styles.td}>
                    <span
                      className={styles.letterBadge}
                      style={{ background: item.color, color: textColorForBg(item.color) }}
                    >
                      {item.letter}
                    </span>
                  </td>
                  <td className={styles.td}>
                    <a
                      href={`https://www.google.com/search?q=${encodeURIComponent([item.common_name, item.scientific_name].filter(Boolean).join(' '))}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className={styles.plantLink}
                    >
                      <div className={styles.plantName}>{item.common_name}</div>
                      {item.scientific_name && (
                        <div className={styles.scientificName}>{item.scientific_name}</div>
                      )}
                    </a>
                  </td>
                  <td className={styles.td}>{item.plant_type}</td>
                  <td className={styles.td}>{item.mature_height_ft} ft</td>
                  <td className={styles.td}>{item.mature_spread_ft} ft</td>
                  <td className={styles.td}>{item.quantity}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
