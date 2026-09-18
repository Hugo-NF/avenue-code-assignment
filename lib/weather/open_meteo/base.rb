require "net/http"
require "json"

module Weather
  module OpenMeteo
    class Base
      DEFAULT_HEADERS = {
        "Accept" => "application/json"
      }.freeze
      CACHE_EXPIRY = ENV.fetch("OPEN_METEO_CACHE_EXPIRY_MINUTES", "30").to_i.minutes

      class ServerError < StandardError; end

      attr_reader :cache_hit, :cached_at

      private

      def cached_request(method_name, *args, **kwargs)
        cache_key = "#{self.class.name}.#{method_name}(#{(args + kwargs.values).join(',')})"
        computed = false

        entry = Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY) do
          computed = true
          { value: yield, cached_at: Time.current }
        end

        @cache_hit = !computed
        @cached_at = entry[:cached_at]
        entry[:value]
      end

      def perform_request(uri, http_verb, headers: {})
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          request = case http_verb
          when :get
            Net::HTTP::Get.new(uri)
          else
            raise ArgumentError, "Weather::OpenMeteo::Base - Unsupported HTTP method: #{http_verb}"
          end

          build_request_headers(headers).each do |key, value|
            request[key] = value
          end

          response = http.request(request)

          unless response.is_a?(Net::HTTPSuccess)
            raise ServerError, "Open-Meteo request failed: #{response.code} #{response.body}"
          end

          JSON.parse(response.body)
        end
      end

      def build_request_headers(request_specific_headers)
        DEFAULT_HEADERS.merge(request_specific_headers)
      end
    end
  end
end
