import type { Design, LegendItem } from '../types'

function textColorForBg(hex: string): string {
  const r = parseInt(hex.slice(1, 3), 16)
  const g = parseInt(hex.slice(3, 5), 16)
  const b = parseInt(hex.slice(5, 7), 16)
  return (0.299 * r + 0.587 * g + 0.114 * b) > 128 ? '#1a1a1a' : '#ffffff'
}

interface Props {
  svg: string | null
  design: Design | null
  legend: LegendItem[] | null
}

export function YardDiagram({ svg, design, legend }: Props) {
  if (!svg || !design) {
    return (
      <div style={styles.empty}>
        <p style={styles.emptyText}>
          Your yard plan will appear here once Claude has enough information to produce a design.
        </p>
      </div>
    )
  }

  return (
    <div style={styles.container}>
      <div
        style={styles.svgWrapper}
        dangerouslySetInnerHTML={{ __html: svg }}
      />
      {legend && legend.length > 0 && (
        <div style={styles.legend}>
          <h3 style={styles.legendTitle}>Plant Legend</h3>
          <table style={styles.table}>
            <thead>
              <tr>
                <th style={styles.th}></th>
                <th style={styles.th}>Plant</th>
                <th style={styles.th}>Type</th>
                <th style={styles.th}>Height</th>
                <th style={styles.th}>Spread</th>
                <th style={styles.th}>Qty</th>
              </tr>
            </thead>
            <tbody>
              {legend.map(item => (
                <tr key={item.letter}>
                  <td style={styles.td}>
                    <span style={{ ...styles.letterBadge, background: item.color, color: textColorForBg(item.color) }}>
                      {item.letter}
                    </span>
                  </td>
                  <td style={styles.td}>
                    <a
                      href={`https://www.google.com/search?q=${encodeURIComponent([item.common_name, item.scientific_name].filter(Boolean).join(' '))}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      style={styles.plantLink}
                    >
                      <div style={styles.plantName}>{item.common_name}</div>
                      {item.scientific_name && (
                        <div style={styles.scientificName}>{item.scientific_name}</div>
                      )}
                    </a>
                  </td>
                  <td style={styles.td}>{item.plant_type}</td>
                  <td style={styles.td}>{item.mature_height_ft} ft</td>
                  <td style={styles.td}>{item.mature_spread_ft} ft</td>
                  <td style={styles.td}>{item.quantity}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

const styles: Record<string, React.CSSProperties> = {
  empty: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    height: '100%',
    padding: '40px',
  },
  emptyText: {
    color: '#999',
    fontSize: '14px',
    lineHeight: '1.6',
    textAlign: 'center',
    maxWidth: '280px',
  },
  container: {
    display: 'flex',
    flexDirection: 'column',
    height: '100%',
    overflowY: 'auto',
    padding: '24px',
    gap: '24px',
  },
  svgWrapper: {
    width: '100%',
    flexShrink: 0,
  },
  legend: {
    flexShrink: 0,
  },
  legendTitle: {
    fontSize: '13px',
    fontWeight: 600,
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
    color: '#6b6b6b',
    marginBottom: '12px',
  },
  table: {
    width: '100%',
    borderCollapse: 'collapse',
    fontSize: '13px',
  },
  th: {
    textAlign: 'left',
    padding: '6px 10px',
    borderBottom: '2px solid #e2ddd8',
    color: '#6b6b6b',
    fontWeight: 500,
    whiteSpace: 'nowrap',
  },
  td: {
    padding: '8px 10px',
    borderBottom: '1px solid #f0ece8',
    verticalAlign: 'top',
  },
  letterBadge: {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    width: '24px',
    height: '24px',
    borderRadius: '50%',
    background: '#2d6a4f',
    color: '#fff',
    fontWeight: 700,
    fontSize: '12px',
  },
  plantLink: {
    textDecoration: 'none',
    color: 'inherit',
  },
  plantName: {
    fontWeight: 500,
    textDecoration: 'underline',
    textDecorationColor: 'rgba(0,0,0,0.2)',
    textUnderlineOffset: '2px',
  },
  scientificName: {
    fontStyle: 'italic',
    color: '#999',
    fontSize: '12px',
    marginTop: '2px',
  },
}
