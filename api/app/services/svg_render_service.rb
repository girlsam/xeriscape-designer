class SvgRenderService
  PADDING   = 40
  MAX_WIDTH = 700
  MAX_HEIGHT = 600

  def self.call(design)
    new(design).call
  end

  def initialize(design)
    @boundary = design[:yard][:boundary]
    @features = design[:yard][:existing_features] || []
    @plants   = design[:plants] || []
  end

  def call
    setup_scale
    build_svg
  end

  private

  def setup_scale
    xs = @boundary.map { |p| p[:x] }
    ys = @boundary.map { |p| p[:y] }

    @min_x  = xs.min
    @min_y  = ys.min
    yard_w  = xs.max - @min_x
    yard_h  = ys.max - @min_y

    @scale  = [ MAX_WIDTH.to_f / yard_w, MAX_HEIGHT.to_f / yard_h ].min
    @svg_w  = (yard_w * @scale + PADDING * 2).ceil
    @svg_h  = (yard_h * @scale + PADDING * 2).ceil
  end

  # Yard feet → SVG pixels
  def sx(ft) = (PADDING + (ft - @min_x) * @scale).round(2)
  def sy(ft) = (PADDING + (ft - @min_y) * @scale).round(2)
  def sp(ft) = (ft * @scale).round(2)

  def build_svg
    <<~SVG.strip
      <svg xmlns="http://www.w3.org/2000/svg" width="#{@svg_w}" height="#{@svg_h}" viewBox="0 0 #{@svg_w} #{@svg_h}">
        #{yard_fill}
        #{yard_outline}
        #{render_features}
        #{render_plants}
      </svg>
    SVG
  end

  def boundary_points
    @boundary.map { |p| "#{sx(p[:x])},#{sy(p[:y])}" }.join(" ")
  end

  def yard_fill
    %(<polygon points="#{boundary_points}" fill="#eef4ee" stroke="none"/>)
  end

  def yard_outline
    %(<polygon points="#{boundary_points}" fill="none" stroke="#4a5240" stroke-width="2"/>)
  end

  def render_features
    @features.map { |f| render_feature(f) }.join("\n  ")
  end

  def render_feature(feature)
    case feature[:type]
    when "tree"     then render_tree(feature)
    when "planter"  then render_rect(feature, fill: "#c8a882", stroke: "#8b6914", text_color: "#4a3000")
    else                 render_rect(feature, fill: "#d8d4ce", stroke: "#9e9a94", text_color: "#444")
    end
  end

  def render_tree(f)
    r     = sp((f[:radius_ft] || 2).to_f)
    cx    = sx(f[:x])
    cy    = sy(f[:y])
    label = f[:label] || "Tree"
    <<~SVG.strip
      <circle cx="#{cx}" cy="#{cy}" r="#{r}" fill="#3a6b28" stroke="#2d5220" stroke-width="1.5" opacity="0.85"/>
      <text x="#{cx}" y="#{cy + 4}" text-anchor="middle" font-size="10" font-family="system-ui" fill="white">#{label}</text>
    SVG
  end

  def render_rect(f, fill:, stroke:, text_color:)
    fx    = sx(f[:x])
    fy    = sy(f[:y])
    fw    = sp((f[:width]  || 4).to_f)
    fh    = sp((f[:height] || 4).to_f)
    label = f[:label] || f[:type].to_s.capitalize
    cx    = fx + fw / 2
    cy    = fy + fh / 2
    <<~SVG.strip
      <rect x="#{fx}" y="#{fy}" width="#{fw}" height="#{fh}" fill="#{fill}" stroke="#{stroke}" stroke-width="1.5"/>
      <text x="#{cx}" y="#{cy + 4}" text-anchor="middle" font-size="10" font-family="system-ui" fill="#{text_color}">#{label}</text>
    SVG
  end

  def render_plants
    @plants.map { |plant| render_plant(plant) }.join("\n  ")
  end

  def render_plant(plant)
    r          = sp(plant[:mature_spread_ft].to_f / 2)
    color      = plant[:color]
    text_color = light_color?(color) ? "#1a1a1a" : "#ffffff"
    font_size  = r.clamp(8, 16).round

    plant[:positions].map do |pos|
      cx = sx(pos[:x])
      cy = sy(pos[:y])
      <<~SVG.strip
        <circle cx="#{cx}" cy="#{cy}" r="#{r}" fill="#{color}" stroke="#{darken(color)}" stroke-width="1.5" opacity="0.85"/>
        <text x="#{cx}" y="#{cy + font_size * 0.35}" text-anchor="middle" font-size="#{font_size}" font-weight="bold" font-family="system-ui" fill="#{text_color}">#{plant[:letter]}</text>
      SVG
    end.join("\n  ")
  end

  def light_color?(hex)
    r = hex[1..2].to_i(16)
    g = hex[3..4].to_i(16)
    b = hex[5..6].to_i(16)
    (0.299 * r + 0.587 * g + 0.114 * b) > 128
  end

  def darken(hex)
    r = (hex[1..2].to_i(16) * 0.7).round.clamp(0, 255)
    g = (hex[3..4].to_i(16) * 0.7).round.clamp(0, 255)
    b = (hex[5..6].to_i(16) * 0.7).round.clamp(0, 255)
    "#%02x%02x%02x" % [ r, g, b ]
  end
end
