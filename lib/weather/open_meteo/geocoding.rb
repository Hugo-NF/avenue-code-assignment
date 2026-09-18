module Weather
  module OpenMeteo
    class Geocoding < Base
      BASE_URL = ENV.fetch("OPEN_METEO_GEOCODING_API_URL", "https://geocoding-api.open-meteo.com/v1/search")

      def search(address, **args)
        cached_request(__method__, address, **args) do
          uri = URI(BASE_URL)
          uri.query = URI.encode_www_form({ name: address, count: 1 }.merge(args))

          perform_request(uri, :get)
        end
      end

      def search_response(response)
        result = response.dig("results", 0)
        return nil unless result

        {
          latitude: result["latitude"],
          longitude: result["longitude"],
          name: result["name"],
          country: result["country"],
          zip_code: result["postcodes"]&.first
        }
      end
    end
  end
end
