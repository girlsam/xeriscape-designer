import type { Design, LegendItem } from '../../types'
import { PlantLegend } from './PlantLegend/PlantLegend'
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
      {legend && legend.length > 0 && <PlantLegend items={legend} />}
    </div>
  )
}
