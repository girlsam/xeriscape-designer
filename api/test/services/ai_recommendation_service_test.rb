require "test_helper"
require "webmock/minitest"

class AiRecommendationServiceTest < ActiveSupport::TestCase
  ZONE_DATA = { zone: "6a", temperature_range: "-10 to -5" }.freeze
  YARD_CONTEXT = Yard.new(
    dimensions: Dimensions.new(width: 20, length: 30, unit: "ft"),
    sun_exposure: "full sun",
    style: "naturalistic",
    yard_features: []
  ).freeze

  DESIGN_JSON = {
    yard: { dimensions: { width: 20, length: 30, unit: "ft" } },
    plants: [
      {
        letter: "A",
        common_name: "Blue Grama Grass",
        scientific_name: "Bouteloua gracilis",
        plant_type: "grass",
        color: "#90EE90",
        mature_spread_ft: 1,
        quantity: 1,
        positions: [ { x: 2, y: 4 } ]
      }
    ]
  }.freeze

  test "returns message and design JSON when Claude produces a complete plan" do
    stub_claude_response(<<~TEXT)
      Based on your zone 6a yard, here's a xeriscape plan suited to your space.

      <design>
      #{DESIGN_JSON.to_json}
      </design>
    TEXT

    result = AiRecommendationService.call(
      zone: ZONE_DATA,
      yard: YARD_CONTEXT,
      messages: [ { role: "user", content: "Please design my yard." } ]
    )

    assert_includes result[:message], "zone 6a"
    assert_equal "Blue Grama Grass", result[:design][:plants].first[:common_name]
  end

  test "returns message with no design when Claude is still gathering context" do
    stub_claude_response("Great, I have your zip code. What are the dimensions of your yard?")

    result = AiRecommendationService.call(
      zone: ZONE_DATA,
      yard: YARD_CONTEXT,
      messages: [ { role: "user", content: "My zip is 80203." } ]
    )

    assert_includes result[:message], "dimensions"
    assert_nil result[:design]
  end

  test "raises APIError when design is missing yard dimensions" do
    bad_design = { plants: DESIGN_JSON[:plants] }

    stub_claude_response(<<~TEXT)
      Here is your plan.

      <design>
      #{bad_design.to_json}
      </design>
    TEXT

    assert_raises(AiRecommendationService::APIError) do
      AiRecommendationService.call(
        zone: ZONE_DATA,
        yard: YARD_CONTEXT,
        messages: [ { role: "user", content: "Please design my yard." } ]
      )
    end
  end

  test "raises APIError when design positions count does not match quantity" do
    bad_design = DESIGN_JSON.dup.tap do |d|
      d[:plants] = [ d[:plants].first.merge(quantity: 5) ]
    end

    stub_claude_response(<<~TEXT)
      Here is your plan.

      <design>
      #{bad_design.to_json}
      </design>
    TEXT

    assert_raises(AiRecommendationService::APIError) do
      AiRecommendationService.call(
        zone: ZONE_DATA,
        yard: YARD_CONTEXT,
        messages: [ { role: "user", content: "Please design my yard." } ]
      )
    end
  end

  test "raises APIError when Claude returns malformed JSON in design block" do
    stub_claude_response(<<~TEXT)
      Here is your plan.

      <design>
      { this is not valid json
      </design>
    TEXT

    assert_raises(AiRecommendationService::APIError) do
      AiRecommendationService.call(
        zone: ZONE_DATA,
        yard: YARD_CONTEXT,
        messages: [ { role: "user", content: "Please design my yard." } ]
      )
    end
  end

  test "raises APIError when Claude API call fails" do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 529, body: { error: { message: "Overloaded" } }.to_json)

    assert_raises(AiRecommendationService::APIError) do
      AiRecommendationService.call(
        zone: ZONE_DATA,
        yard: YARD_CONTEXT,
        messages: [ { role: "user", content: "Please design my yard." } ]
      )
    end
  end

  private

  def stub_claude_response(text)
    # The Anthropic SDK deserializes loosely — id, stop_reason, and usage are
    # not required for the content parsing path we exercise here.
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: {
          content: [ { type: "text", text: text } ],
          model: "claude-sonnet-4-6",
          role: "assistant"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
