require "net/http"
require "json"

class ZoneLookupService
  class ZoneNotFoundError < StandardError; end
  class NetworkError < StandardError; end

  BASE_URL = "https://phzmapi.org"

  def self.call(zip_code)
    new(zip_code).call
  end

  def initialize(zip_code)
    @zip_code = zip_code
  end

  def call
    response = fetch
    parse(response)
  end

  private

  def fetch
    uri = URI("#{BASE_URL}/#{@zip_code}.json")
    Net::HTTP.get_response(uri)
  rescue SocketError, Errno::ECONNREFUSED => e
    raise NetworkError, e.message
  end

  def parse(response)
    raise ZoneNotFoundError, "No zone found for zip code #{@zip_code}" unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body, symbolize_names: true)
    { zone: body[:zone], temperature_range: body[:temperature_range] }
  end
end
