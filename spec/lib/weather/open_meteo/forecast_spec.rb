require "rails_helper"

RSpec.describe Weather::OpenMeteo::Forecast do
  subject(:client) { described_class.new }

  let(:default_args) do
    { temperature_unit: "celsius", wind_speed_unit: "kmh", precipitation_unit: "mm", forecast_hours: 24 }
  end

  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = original_cache
  end

  describe "#fetch", :vcr do
    context "when the coordinates are valid" do
      it "returns the raw forecast response", :aggregate_failures do
        response = client.fetch(37.38605, -122.08385, **default_args)

        expect(response).to have_key("current")
        expect(response).to have_key("daily")
        expect(response).to have_key("hourly")
      end
    end

    context "when the coordinates are invalid" do
      it "raises a server error" do
        expect { client.fetch(999, 999, **default_args) }.to raise_error(Weather::OpenMeteo::Base::ServerError)
      end
    end

    context "when called twice with the same arguments" do
      it "caches the response", :aggregate_failures do
        client.fetch(37.38605, -122.08385, **default_args)
        expect(client.cache_hit).to be(false)

        client.fetch(37.38605, -122.08385, **default_args)
        expect(client.cache_hit).to be(true)
      end
    end

    context "when called with a different temperature unit" do
      it "performs a new request" do
        client.fetch(37.38605, -122.08385, **default_args)
        client.fetch(37.38605, -122.08385, **default_args.merge(temperature_unit: "fahrenheit"))

        expect(client.cache_hit).to be(false)
      end
    end

    context "when called with a different forecast window" do
      it "performs a new request" do
        client.fetch(37.38605, -122.08385, **default_args)
        client.fetch(37.38605, -122.08385, **default_args.merge(forecast_hours: 48))

        expect(client.cache_hit).to be(false)
      end
    end
  end

  describe "#fetch_response" do
    context "when the response has data" do
      let(:response) do
        {
          "current" => {
            "temperature_2m" => 65.7,
            "apparent_temperature" => 64.2,
            "relative_humidity_2m" => 58,
            "weather_code" => 1,
            "cloud_cover" => 40,
            "surface_pressure" => 1016.5
          },
          "daily" => {
            "time" => %w[2026-09-17 2026-09-18],
            "temperature_2m_max" => [ 72.5, 71.4 ],
            "temperature_2m_min" => [ 58.7, 56.6 ],
            "sunrise" => %w[2026-09-17T06:52 2026-09-18T06:53],
            "sunset" => %w[2026-09-17T19:11 2026-09-18T19:09],
            "uv_index_max" => [ 6.5, 6.55 ]
          },
          "hourly" => {
            "time" => %w[2026-09-17T10:00 2026-09-17T11:00],
            "temperature_2m" => [ 63.1, 65.7 ],
            "precipitation" => [ 0.0, 0.2 ],
            "precipitation_probability" => [ 5, 10 ],
            "wind_speed_10m" => [ 8.4, 9.0 ],
            "wind_gusts_10m" => [ 10.1, 11.5 ],
            "wind_direction_10m" => [ 356, 7 ],
            "weather_code" => [ 1, 61 ],
            "dew_point_2m" => [ 12.1, 12.6 ],
            "cloud_cover" => [ 40, 45 ],
            "surface_pressure" => [ 1016.5, 1016.2 ],
            "visibility" => [ 24000, 22000 ],
            "uv_index" => [ 3.1, 4.2 ],
            "soil_temperature_0cm" => [ 18.2, 18.6 ],
            "soil_moisture_0_to_1cm" => [ 0.21, 0.22 ]
          }
        }
      end

      it "extracts the current conditions", :aggregate_failures do
        result = client.fetch_response(response)

        expect(result[:current_temperature]).to eq(65.7)
        expect(result[:feels_like_temperature]).to eq(64.2)
        expect(result[:humidity]).to eq(58)
        expect(result[:weather_condition]).to eq("Mainly clear")
        expect(result[:cloud_cover]).to eq(40)
        expect(result[:pressure]).to eq(1016.5)
      end

      it "extracts the daily forecast", :aggregate_failures do
        result = client.fetch_response(response)

        expect(result[:high_temperature]).to eq(72.5)
        expect(result[:low_temperature]).to eq(58.7)
        expect(result[:daily_highs]).to eq([ 72.5, 71.4 ])
        expect(result[:daily_lows]).to eq([ 58.7, 56.6 ])
        expect(result[:dates]).to eq(%w[2026-09-17 2026-09-18])
        expect(result[:sunrise]).to eq("2026-09-17T06:52")
        expect(result[:sunset]).to eq("2026-09-17T19:11")
        expect(result[:daily_uv_index_max]).to eq(6.5)
      end

      it "builds the hourly forecast by zipping the parallel arrays by index", :aggregate_failures do
        result = client.fetch_response(response)

        expect(result[:hourly_forecast].size).to eq(2)

        expect(result[:hourly_forecast][0]).to include(
          time: "2026-09-17T10:00",
          temperature: 63.1,
          precipitation: 0.0,
          precipitation_probability: 5,
          wind_speed: 8.4,
          wind_gusts: 10.1,
          wind_direction: 356,
          weather_condition: "Mainly clear",
          dew_point: 12.1,
          cloud_cover: 40,
          pressure: 1016.5,
          visibility: 24000,
          uv_index: 3.1,
          soil_temperature: 18.2,
          soil_moisture: 0.21
        )

        expect(result[:hourly_forecast][1]).to include(
          time: "2026-09-17T11:00",
          temperature: 65.7,
          precipitation: 0.2,
          precipitation_probability: 10,
          wind_speed: 9.0,
          wind_gusts: 11.5,
          wind_direction: 7,
          weather_condition: "Slight rain",
          dew_point: 12.6,
          cloud_cover: 45,
          pressure: 1016.2,
          visibility: 22000,
          uv_index: 4.2,
          soil_temperature: 18.6,
          soil_moisture: 0.22
        )
      end

      it "uses the first hourly entry as the 'now' snapshot for fields absent from the current block", :aggregate_failures do
        result = client.fetch_response(response)

        expect(result[:dew_point]).to eq(12.1)
        expect(result[:visibility]).to eq(24000)
        expect(result[:soil_temperature]).to eq(18.2)
        expect(result[:soil_moisture]).to eq(0.21)
      end
    end

    context "when the response has no data" do
      it "returns nil values", :aggregate_failures do
        result = client.fetch_response({})

        expect(result[:current_temperature]).to be_nil
        expect(result[:feels_like_temperature]).to be_nil
        expect(result[:humidity]).to be_nil
        expect(result[:weather_condition]).to be_nil
        expect(result[:cloud_cover]).to be_nil
        expect(result[:pressure]).to be_nil
        expect(result[:dew_point]).to be_nil
        expect(result[:visibility]).to be_nil
        expect(result[:soil_temperature]).to be_nil
        expect(result[:soil_moisture]).to be_nil
        expect(result[:high_temperature]).to be_nil
        expect(result[:daily_highs]).to be_nil
        expect(result[:sunrise]).to be_nil
        expect(result[:sunset]).to be_nil
        expect(result[:daily_uv_index_max]).to be_nil
        expect(result[:hourly_forecast]).to eq([])
      end
    end
  end
end
