module Weather
  module OpenMeteo
    module AqiCategory
      BANDS = {
        (0..50) => "Good",
        (51..100) => "Moderate",
        (101..150) => "Unhealthy for Sensitive Groups",
        (151..200) => "Unhealthy",
        (201..300) => "Very Unhealthy"
      }.freeze

      def self.describe(us_aqi)
        return nil if us_aqi.nil?

        value = us_aqi.to_i
        BANDS.each do |range, label|
          return label if range.cover?(value)
        end

        "Hazardous"
      end
    end
  end
end
