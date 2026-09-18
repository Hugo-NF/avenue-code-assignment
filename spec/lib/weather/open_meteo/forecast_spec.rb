require "rails_helper"

RSpec.describe Weather::OpenMeteo::Forecast do
  subject(:client) { described_class.new }

  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = original_cache
  end

  describe "#fetch", :vcr do
    context "when the coordinates are valid" do
      it "returns the raw forecast response", :aggregate_failures do
        response = client.fetch(37.38605, -122.08385)

        expect(response).to have_key("current")
        expect(response).to have_key("daily")
      end
    end

    context "when the coordinates are invalid" do
      it "raises a server error" do
        expect { client.fetch(999, 999) }.to raise_error(Weather::OpenMeteo::Base::ServerError)
      end
    end

    context "when called twice with the same arguments" do
      it "caches the response", :aggregate_failures do
        client.fetch(37.38605, -122.08385)
        expect(client.cache_hit).to be(false)

        client.fetch(37.38605, -122.08385)
        expect(client.cache_hit).to be(true)
      end
    end

    context "when called with different arguments" do
      it "performs a new request" do
        client.fetch(37.38605, -122.08385)
        client.fetch(37.38605, -122.08385, temperature_unit: "fahrenheit")

        expect(client.cache_hit).to be(false)
      end
    end
  end

  describe "#fetch_response" do
    context "when the response has data" do
      let(:response) do
        {
          "current" => { "temperature_2m" => 65.7 },
          "daily" => {
            "time" => %w[2026-09-17 2026-09-18],
            "temperature_2m_max" => [ 72.5, 71.4 ],
            "temperature_2m_min" => [ 58.7, 56.6 ]
          }
        }
      end

      it "extracts the temperatures", :aggregate_failures do
        result = client.fetch_response(response)

        expect(result[:current_temperature]).to eq(65.7)
        expect(result[:high_temperature]).to eq(72.5)
        expect(result[:low_temperature]).to eq(58.7)
        expect(result[:daily_highs]).to eq([ 72.5, 71.4 ])
        expect(result[:daily_lows]).to eq([ 58.7, 56.6 ])
        expect(result[:dates]).to eq(%w[2026-09-17 2026-09-18])
      end
    end

    context "when the response has no data" do
      it "returns nil values", :aggregate_failures do
        result = client.fetch_response({})

        expect(result[:current_temperature]).to be_nil
        expect(result[:high_temperature]).to be_nil
        expect(result[:daily_highs]).to be_nil
      end
    end
  end
end
