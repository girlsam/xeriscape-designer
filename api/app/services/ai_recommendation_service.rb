require "anthropic"

class AiRecommendationService
  class APIError < StandardError; end

  MODEL = "claude-sonnet-4-6"
  MAX_TOKENS = 8192
  SYSTEM_PROMPT = File.read(Rails.root.join("app/prompts/xeriscape_designer.txt")).freeze

  def self.call(zone:, yard:, messages:)
    new(zone: zone, yard: yard, messages: messages).call
  end

  def initialize(zone:, yard:, messages:)
    @zone = zone
    @yard = yard
    @messages = messages
  end

  def call
    response_text = fetch_response
    parse(response_text)
  end

  private

  def fetch_response
    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    response = client.messages.create(
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: system_prompt_with_context,
      messages: @messages
    )

    raise APIError, "Unexpected response format" unless response.content.first.is_a?(Anthropic::Models::TextBlock)

    response.content.first.text
  rescue Anthropic::Errors::APIStatusError => e
    raise APIError, e.message
  end

  # @TODO: validate sun_exposure and style are constrained enum values before interpolation
  def system_prompt_with_context
    <<~PROMPT
      #{SYSTEM_PROMPT}

      Current yard context:
      - USDA Hardiness Zone: #{@zone[:zone]} (#{@zone[:temperature_range]}°F)
      - Dimensions: #{@yard.dimensions.width} x #{@yard.dimensions.length} #{@yard.dimensions.unit}
      - Sun exposure: #{@yard.sun_exposure}
      - Style: #{@yard.style}
      - Existing yard features: #{format_yard_features}
    PROMPT
  end

  def format_yard_features
    return "none" if @yard.yard_features.blank?

    @yard.yard_features.map { |e| "#{e.type} at (#{e.x}, #{e.y})" }.join(", ")
  end

  def parse(text)
    design = extract_design(text)
    message = text.gsub(/<design>.*<\/design>/m, "").strip

    { message: message, design: design }
  end

  REQUIRED_PLANT_KEYS = %i[letter common_name plant_type color mature_spread_ft quantity positions].freeze

  def extract_design(text)
    match = text.match(/<design>\s*(.*?)\s*<\/design>/m)
    return nil unless match

    design = JSON.parse(match[1], symbolize_names: true)
    validate_design!(design)
    design
  rescue JSON::ParserError
    raise APIError, "Claude returned a malformed design block"
  end

  def validate_design!(design)
    raise APIError, "Design is missing yard dimensions" unless design.dig(:yard, :dimensions)

    plants = design[:plants]
    raise APIError, "Design is missing a plants array" unless plants.is_a?(Array) && plants.any?

    plants.each_with_index do |plant, i|
      missing = REQUIRED_PLANT_KEYS - plant.keys
      raise APIError, "Plant #{i + 1} is missing keys: #{missing.join(', ')}" if missing.any?

      unless plant[:positions].length == plant[:quantity]
        raise APIError, "Plant #{plant[:letter]}: positions count (#{plant[:positions].length}) does not match quantity (#{plant[:quantity]})"
      end
    end
  end
end
