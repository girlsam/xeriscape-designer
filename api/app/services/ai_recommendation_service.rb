require "anthropic"

class AiRecommendationService
  class APIError < StandardError; end

  MODEL = "claude-sonnet-4-6"
  MAX_TOKENS = 8192
  SYSTEM_PROMPT = File.read(Rails.root.join("app/prompts/xeriscape_designer.txt")).freeze

  def self.call(messages:, current_design: nil, zone: nil)
    new(messages: messages, current_design: current_design, zone: zone).call
  end

  def initialize(messages:, current_design: nil, zone: nil)
    @messages = messages
    @current_design = current_design
    @zone = zone
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

  def system_prompt_with_context
    prompt = if @current_design
      SYSTEM_PROMPT.sub("{{CURRENT_DESIGN}}", refinement_content)
    else
      SYSTEM_PROMPT.gsub(/<current_design>\s*\{\{CURRENT_DESIGN\}\}\s*<\/current_design>\n?/, "")
    end

    if @zone
      prompt += "\n\nZone context:\n- USDA Hardiness Zone: #{@zone[:zone]} (#{@zone[:temperature_range]}°F)"
    end

    prompt
  end

  def refinement_content
    <<~REFINEMENT.strip
      The user is refining this design. Modify it based on their request and produce an updated <design> block. Do not start over.
      <design>
      #{@current_design.to_json}
      </design>
    REFINEMENT
  end

  def parse(text)
    design = extract_design(text)
    message = text.gsub(/<design>.*<\/design>/m, "").strip

    { message: message, design: design }
  end

  REQUIRED_PLANT_KEYS = %i[letter common_name plant_type color mature_spread_ft mature_height_ft quantity positions].freeze

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
    raise APIError, "Design is missing yard boundary" unless design.dig(:yard, :boundary).is_a?(Array)

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
