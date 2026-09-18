module Weather
  module OpenMeteo
    class Forecast < Base
      BASE_URL = ENV.fetch("OPEN_METEO_FORECAST_API_URL", "https://api.open-meteo.com/v1/forecast")

      def fetch(latitude, longitude, **args)
        cached_request(__method__, latitude, longitude, **args) do
          uri = URI(BASE_URL)
          uri.query = URI.encode_www_form({
            latitude: latitude,
            longitude: longitude,
            current: "temperature_2m",
            daily: "temperature_2m_max,temperature_2m_min",
            temperature_unit: "celsius",
            timezone: "auto"
          }.merge(args))

          perform_request(uri, :get)
        end
      end

      def fetch_response(response)
        {
          current_temperature: response.dig("current", "temperature_2m"),
          high_temperature: response.dig("daily", "temperature_2m_max", 0),
          low_temperature: response.dig("daily", "temperature_2m_min", 0),
          daily_highs: response.dig("daily", "temperature_2m_max"),
          daily_lows: response.dig("daily", "temperature_2m_min"),
          dates: response.dig("daily", "time")
        }
      end
    end
  end
end
