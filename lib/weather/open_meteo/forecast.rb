module Weather
  module OpenMeteo
    class Forecast < Base
      BASE_URL = ENV.fetch("OPEN_METEO_FORECAST_API_URL", "https://api.open-meteo.com/v1/forecast")

      CURRENT_FIELDS = %w[
        temperature_2m apparent_temperature relative_humidity_2m weather_code
        cloud_cover surface_pressure
      ].freeze

      DAILY_FIELDS = %w[
        temperature_2m_max temperature_2m_min sunrise sunset uv_index_max
      ].freeze

      HOURLY_FIELDS = %w[
        temperature_2m precipitation precipitation_probability wind_speed_10m
        wind_gusts_10m wind_direction_10m weather_code dew_point_2m cloud_cover
        surface_pressure visibility uv_index soil_temperature_0cm soil_moisture_0_to_1cm
      ].freeze

      def fetch(latitude, longitude, temperature_unit:, wind_speed_unit:, precipitation_unit:, forecast_hours:)
        cached_request(__method__, latitude, longitude,
          temperature_unit: temperature_unit,
          wind_speed_unit: wind_speed_unit,
          precipitation_unit: precipitation_unit,
          forecast_hours: forecast_hours) do
          uri = URI(BASE_URL)
          uri.query = URI.encode_www_form(
            latitude: latitude,
            longitude: longitude,
            current: CURRENT_FIELDS.join(","),
            daily: DAILY_FIELDS.join(","),
            hourly: HOURLY_FIELDS.join(","),
            temperature_unit: temperature_unit,
            wind_speed_unit: wind_speed_unit,
            precipitation_unit: precipitation_unit,
            forecast_hours: forecast_hours,
            timezone: "auto"
          )

          perform_request(uri, :get)
        end
      end

      def fetch_response(response)
        hourly = hourly_forecast(response)
        now = hourly.first

        {
          current_temperature: response.dig("current", "temperature_2m"),
          feels_like_temperature: response.dig("current", "apparent_temperature"),
          humidity: response.dig("current", "relative_humidity_2m"),
          weather_condition: WeatherCode.describe(response.dig("current", "weather_code")),
          cloud_cover: response.dig("current", "cloud_cover"),
          pressure: response.dig("current", "surface_pressure"),
          dew_point: now && now[:dew_point],
          visibility: now && now[:visibility],
          soil_temperature: now && now[:soil_temperature],
          soil_moisture: now && now[:soil_moisture],
          high_temperature: response.dig("daily", "temperature_2m_max", 0),
          low_temperature: response.dig("daily", "temperature_2m_min", 0),
          daily_highs: response.dig("daily", "temperature_2m_max"),
          daily_lows: response.dig("daily", "temperature_2m_min"),
          dates: response.dig("daily", "time"),
          sunrise: response.dig("daily", "sunrise", 0),
          sunset: response.dig("daily", "sunset", 0),
          daily_uv_index_max: response.dig("daily", "uv_index_max", 0),
          hourly_forecast: hourly
        }
      end

      private

      def hourly_forecast(response)
        hourly = response["hourly"]
        return [] unless hourly

        times = hourly["time"] || []
        times.each_index.map do |i|
          {
            time: times[i],
            temperature: hourly.dig("temperature_2m", i),
            precipitation: hourly.dig("precipitation", i),
            precipitation_probability: hourly.dig("precipitation_probability", i),
            wind_speed: hourly.dig("wind_speed_10m", i),
            wind_gusts: hourly.dig("wind_gusts_10m", i),
            wind_direction: hourly.dig("wind_direction_10m", i),
            weather_condition: WeatherCode.describe(hourly.dig("weather_code", i)),
            dew_point: hourly.dig("dew_point_2m", i),
            cloud_cover: hourly.dig("cloud_cover", i),
            pressure: hourly.dig("surface_pressure", i),
            visibility: hourly.dig("visibility", i),
            uv_index: hourly.dig("uv_index", i),
            soil_temperature: hourly.dig("soil_temperature_0cm", i),
            soil_moisture: hourly.dig("soil_moisture_0_to_1cm", i)
          }
        end
      end
    end
  end
end
