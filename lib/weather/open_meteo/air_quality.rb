module Weather
  module OpenMeteo
    class AirQuality < Base
      BASE_URL = ENV.fetch("OPEN_METEO_AIR_QUALITY_API_URL", "https://air-quality-api.open-meteo.com/v1/air-quality")

      CURRENT_FIELDS = %w[us_aqi european_aqi pm2_5 pm10].freeze

      def fetch(latitude, longitude)
        cached_request(__method__, latitude, longitude) do
          uri = URI(BASE_URL)
          uri.query = URI.encode_www_form(
            latitude: latitude,
            longitude: longitude,
            current: CURRENT_FIELDS.join(","),
            timezone: "auto"
          )

          perform_request(uri, :get)
        end
      end

      def fetch_response(response)
        {
          us_aqi: response.dig("current", "us_aqi"),
          us_aqi_category: AqiCategory.describe(response.dig("current", "us_aqi")),
          european_aqi: response.dig("current", "european_aqi"),
          pm2_5: response.dig("current", "pm2_5"),
          pm10: response.dig("current", "pm10")
        }
      end
    end
  end
end
