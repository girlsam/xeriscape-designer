require "test_helper"

class SvgRenderServiceTest < ActiveSupport::TestCase
  DESIGN = {
    yard: {
      boundary: [
        { x: 0, y: 0 }, { x: 20, y: 0 }, { x: 20, y: 30 }, { x: 0, y: 30 }
      ],
      unit: "ft",
      existing_features: [
        { type: "tree",    label: "Oak",     x: 10, y: 10, radius_ft: 3 },
        { type: "planter", label: "Planter", x: 2,  y: 25, width: 8, height: 4 }
      ]
    },
    plants: [
      {
        letter: "A",
        common_name: "Blue Grama Grass",
        plant_type: "grass",
        color: "#90EE90",
        mature_spread_ft: 2,
        quantity: 2,
        positions: [ { x: 4, y: 5 }, { x: 8, y: 5 } ]
      },
      {
        letter: "B",
        common_name: "Fragrant Sumac",
        plant_type: "shrub",
        color: "#8B4513",
        mature_spread_ft: 6,
        quantity: 1,
        positions: [ { x: 15, y: 20 } ]
      }
    ]
  }.freeze

  test "returns a valid SVG string" do
    svg = SvgRenderService.call(DESIGN)
    assert svg.start_with?("<svg")
    assert svg.end_with?("</svg>")
  end

  test "SVG has width and height attributes" do
    svg = SvgRenderService.call(DESIGN)
    assert_match(/width="\d+"/, svg)
    assert_match(/height="\d+"/, svg)
  end

  test "renders the yard boundary" do
    svg = SvgRenderService.call(DESIGN)
    assert_equal 3, svg.scan("<polygon").count
  end

  test "renders grid lines at 2 ft intervals clipped to yard boundary" do
    svg = SvgRenderService.call(DESIGN)
    # 20x30 ft yard: x=0,2..20 → 11 vertical, y=0,2..30 → 16 horizontal = 27 lines
    assert_equal 27, svg.scan("<line").count
    assert_includes svg, "clip-path"
  end

  test "renders each plant position and circular existing feature" do
    svg = SvgRenderService.call(DESIGN)
    # 2 positions for A + 1 for B + 1 tree = 4
    assert_equal 4, svg.scan("<circle").count
  end

  test "renders plant letter labels" do
    svg = SvgRenderService.call(DESIGN)
    assert_includes svg, ">A<"
    assert_includes svg, ">B<"
  end

  test "renders plant colors" do
    svg = SvgRenderService.call(DESIGN)
    assert_includes svg, "#90EE90"
    assert_includes svg, "#8B4513"
  end

  test "renders tree feature with label" do
    svg = SvgRenderService.call(DESIGN)
    assert_includes svg, "Oak"
  end

  test "renders planter features with a label" do
    svg = SvgRenderService.call(DESIGN)
    assert_includes svg, "<rect"
    assert_includes svg, "Planter"
  end

  test "renders path and fence features as a generic shape" do
    design = {
      yard: DESIGN[:yard].merge(existing_features: [
        { type: "path",  label: "Front path", x: 5, y: 0, width: 3, height: 10 },
        { type: "fence", label: "Side fence", x: 0, y: 0, width: 1, height: 30 }
      ]),
      plants: []
    }
    svg = SvgRenderService.call(design)
    assert_includes svg, "<rect"
    assert_includes svg, "Front path"
    assert_includes svg, "Side fence"
  end

  test "works with no existing features" do
    design = { yard: DESIGN[:yard].merge(existing_features: []), plants: DESIGN[:plants] }
    svg = SvgRenderService.call(design)
    assert svg.start_with?("<svg")
    assert_equal 0, svg.scan("<rect").count
  end

  test "uses dark text on light plant colors" do
    svg = SvgRenderService.call(DESIGN)
    assert_includes svg, "#1a1a1a"
  end

  test "uses light text on dark plant colors" do
    svg = SvgRenderService.call(DESIGN)
    assert_includes svg, "#ffffff"
  end
end
