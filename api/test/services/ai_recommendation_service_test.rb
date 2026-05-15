require "test_helper"
require "webmock/minitest"

class AiRecommendationServiceTest < ActiveSupport::TestCase
  ZONE_DATA = { zone: "6a", temperature_range: "-10 to -5" }.freeze

  DESIGN_JSON = {
    yard: {
      boundary: [ { x: 0, y: 0 }, { x: 20, y: 0 }, { x: 20, y: 30 }, { x: 0, y: 30 } ],
      unit: "ft",
      existing_features: []
    },
    plants: [
      {
        letter: "A",
        common_name: "Blue Grama Grass",
        scientific_name: "Bouteloua gracilis",
        plant_type: "grass",
        color: "#90EE90",
        mature_spread_ft: 1,
        mature_height_ft: 1.5,
        quantity: 1,
        positions: [ { x: 2, y: 4 } ]
      }
    ]
  }.freeze

  MESSAGES = [ { role: "user", content: "Please design my yard." } ].freeze

  test "returns message and design JSON when Claude produces a complete plan" do
    stub_claude_response(<<~TEXT)
      Based on your zone 6a yard, here's a xeriscape plan suited to your space.

      <design>
      #{DESIGN_JSON.to_json}
      </design>
    TEXT

    result = AiRecommendationService.call(messages: MESSAGES, zone: ZONE_DATA)

    assert_includes result[:message], "zone 6a"
    assert_equal "Blue Grama Grass", result[:design][:plants].first[:common_name]
  end

  test "returns message with no design when Claude is still gathering context" do
    stub_claude_response("Got it. What are the dimensions of your yard?")

    result = AiRecommendationService.call(
      messages: [ { role: "user", content: "My zip is 80203." } ]
    )

    assert_includes result[:message], "dimensions"
    assert_nil result[:design]
  end

  test "injects current_design into system prompt for refinement turns" do
    stub_claude_response(<<~TEXT)
      I've added more purple-flowering plants.

      <design>
      #{DESIGN_JSON.to_json}
      </design>
    TEXT

    # Verify the request body includes the current design in the system prompt
    stub = stub_request(:post, "https://api.anthropic.com/v1/messages")
      .with { |req| JSON.parse(req.body)["system"].include?("The user is refining this design") }
      .to_return(
        status: 200,
        body: {
          content: [ { type: "text", text: "Updated design.\n<design>\n#{DESIGN_JSON.to_json}\n</design>" } ],
          model: "claude-sonnet-4-6",
          role: "assistant"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    AiRecommendationService.call(
      messages: [ { role: "user", content: "More purple please." } ],
      current_design: DESIGN_JSON
    )

    assert_requested stub
  end

  test "raises APIError when design is missing yard boundary" do
    bad_design = { yard: {}, plants: DESIGN_JSON[:plants] }

    stub_claude_response(<<~TEXT)
      Here is your plan.

      <design>
      #{bad_design.to_json}
      </design>
    TEXT

    assert_raises(AiRecommendationService::APIError) do
      AiRecommendationService.call(messages: MESSAGES)
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
      AiRecommendationService.call(messages: MESSAGES)
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
      AiRecommendationService.call(messages: MESSAGES)
    end
  end

  test "raises APIError when Claude API call fails" do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 529, body: { error: { message: "Overloaded" } }.to_json)

    assert_raises(AiRecommendationService::APIError) do
      AiRecommendationService.call(messages: MESSAGES)
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
