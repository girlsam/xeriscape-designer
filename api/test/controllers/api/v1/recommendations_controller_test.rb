require "test_helper"
require "webmock/minitest"

class Api::V1::RecommendationsControllerTest < ActionDispatch::IntegrationTest
  MESSAGES = [ { role: "user", content: "My zip is 80203." } ].freeze

  DESIGN = {
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
        mature_spread_ft: 2,
        mature_height_ft: 1.5,
        quantity: 1,
        positions: [ { x: 4, y: 5 } ]
      }
    ]
  }.freeze

  # --- happy path: no design yet ---

  test "returns message only when Claude is still gathering context" do
    stub_claude("What are your yard dimensions?")

    post api_v1_recommendations_path,
      params: { messages: MESSAGES },
      as: :json

    assert_response :ok
    body = response.parsed_body
    assert_equal "What are your yard dimensions?", body["message"]
    assert_nil body["design"]
    assert_nil body["svg"]
    assert_nil body["legend"]
  end

  # --- happy path: design returned ---

  test "returns message, design, svg, and legend when Claude produces a plan" do
    stub_claude("Here is your plan.\n\n<design>\n#{DESIGN.to_json}\n</design>")

    post api_v1_recommendations_path,
      params: { messages: MESSAGES },
      as: :json

    assert_response :ok
    body = response.parsed_body
    assert_equal "Here is your plan.", body["message"]
    assert_not_nil body["design"]
    assert_not_nil body["svg"]
    assert_equal 1, body["legend"].length
    assert_equal "A", body["legend"].first["letter"]
    assert_equal "Blue Grama Grass", body["legend"].first["common_name"]
  end

  # --- zip code / zone handling ---

  test "looks up the hardiness zone when a zip code is provided" do
    stub_zone("80203")
    stub_claude("Got it.")

    post api_v1_recommendations_path,
      params: { messages: MESSAGES, zip_code: "80203" },
      as: :json

    assert_response :ok
    assert_requested :get, "https://phzmapi.org/80203.json"
  end

  test "uses the zip code from the existing design when none is provided separately" do
    stub_zone("80203")
    stub_claude("Got it.")
    current_design = DESIGN.merge(zip_code: "80203")

    post api_v1_recommendations_path,
      params: { messages: MESSAGES, current_design: current_design },
      as: :json

    assert_response :ok
    assert_requested :get, "https://phzmapi.org/80203.json"
  end

  test "does not make a zone request when no zip code is known" do
    stub_claude("What's your zip code?")

    post api_v1_recommendations_path,
      params: { messages: MESSAGES },
      as: :json

    assert_response :ok
    assert_not_requested :get, "https://phzmapi.org/80203.json"
  end

  # --- error handling ---

  test "returns 422 when Claude API call fails" do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 529, body: { error: { message: "Overloaded" } }.to_json)

    post api_v1_recommendations_path,
      params: { messages: MESSAGES },
      as: :json

    assert_response :unprocessable_entity
    assert_not_nil response.parsed_body["error"]
  end

  test "returns 422 when zip code is not recognized" do
    stub_request(:get, "https://phzmapi.org/00000.json")
      .to_return(status: 404, body: "")

    post api_v1_recommendations_path,
      params: { messages: MESSAGES, zip_code: "00000" },
      as: :json

    assert_response :unprocessable_entity
    assert_not_nil response.parsed_body["error"]
  end

  test "returns 503 when zone lookup fails with a network error" do
    stub_request(:get, "https://phzmapi.org/80203.json")
      .to_raise(SocketError.new("connection refused"))

    post api_v1_recommendations_path,
      params: { messages: MESSAGES, zip_code: "80203" },
      as: :json

    assert_response :service_unavailable
    assert_not_nil response.parsed_body["error"]
  end

  test "returns 400 when messages param is missing" do
    post api_v1_recommendations_path,
      params: {},
      as: :json

    assert_response :bad_request
  end

  # --- legend shape ---

  test "legend items contain expected fields" do
    stub_claude("Here is your plan.\n\n<design>\n#{DESIGN.to_json}\n</design>")

    post api_v1_recommendations_path,
      params: { messages: MESSAGES },
      as: :json

    item = response.parsed_body["legend"].first
    assert_equal %w[letter common_name scientific_name plant_type color mature_spread_ft mature_height_ft quantity], item.keys
  end

  private

  def stub_claude(text)
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

  def stub_zone(zip)
    stub_request(:get, "https://phzmapi.org/#{zip}.json")
      .to_return(
        status: 200,
        body: { zone: "6a", temperature_range: "-10 to -5" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
