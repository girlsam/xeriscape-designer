require "test_helper"
require "webmock/minitest"

class ZoneLookupServiceTest < ActiveSupport::TestCase
  VALID_ZIP = "80203"
  INVALID_ZIP = "00000"
  API_URL = "https://phzmapi.org"

  test "returns zone and temperature range for a valid zip code" do
    stub_request(:get, "#{API_URL}/#{VALID_ZIP}.json")
      .to_return(
        status: 200,
        body: {
          zone: "6a",
          temperature_range: "-10 to -5",
          coordinates: { lat: "39.7", lon: "-104.9" }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = ZoneLookupService.call(VALID_ZIP)

    assert_equal "6a", result[:zone]
    assert_equal "-10 to -5", result[:temperature_range]
  end

  test "raises ZoneNotFoundError when zip code is not recognized" do
    stub_request(:get, "#{API_URL}/#{INVALID_ZIP}.json")
      .to_return(status: 404, body: "")

    assert_raises(ZoneLookupService::ZoneNotFoundError) do
      ZoneLookupService.call(INVALID_ZIP)
    end
  end

  test "raises ZoneNotFoundError for a malformed zip code" do
    malformed_zip = "123"

    stub_request(:get, "#{API_URL}/#{malformed_zip}.json")
      .to_return(status: 404, body: "")

    assert_raises(ZoneLookupService::ZoneNotFoundError) do
      ZoneLookupService.call(malformed_zip)
    end
  end

  test "raises NetworkError on connection failure" do
    stub_request(:get, "#{API_URL}/#{VALID_ZIP}.json")
      .to_raise(SocketError)

    assert_raises(ZoneLookupService::NetworkError) do
      ZoneLookupService.call(VALID_ZIP)
    end
  end
end
