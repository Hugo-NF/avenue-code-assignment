require "rails_helper"

RSpec.describe Weather::OpenMeteo::AirQuality do
  subject(:client) { described_class.new }

  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = original_cache
  end

  describe "#fetch", :vcr do
    context "when the coordinates are valid" do
      it "returns the raw air quality response", :aggregate_failures do
        response = client.fetch(37.38605, -122.08385)

        expect(response).to have_key("current")
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

    context "when called with different coordinates" do
      it "performs a new request" do
        client.fetch(37.38605, -122.08385)
        client.fetch(40.71427, -74.00597)

        expect(client.cache_hit).to be(false)
      end
    end
  end

  describe "#fetch_response" do
    context "when the response has data" do
      let(:response) do
        {
          "current" => {
            "us_aqi" => 42,
            "european_aqi" => 28,
            "pm2_5" => 11.4,
            "pm10" => 15.0
          }
        }
      end

      it "extracts the air quality data", :aggregate_failures do
        result = client.fetch_response(response)

        expect(result[:us_aqi]).to eq(42)
        expect(result[:us_aqi_category]).to eq("Good")
        expect(result[:european_aqi]).to eq(28)
        expect(result[:pm2_5]).to eq(11.4)
        expect(result[:pm10]).to eq(15.0)
      end
    end

    context "when the response has no data" do
      it "returns nil values", :aggregate_failures do
        result = client.fetch_response({})

        expect(result[:us_aqi]).to be_nil
        expect(result[:us_aqi_category]).to be_nil
        expect(result[:european_aqi]).to be_nil
        expect(result[:pm2_5]).to be_nil
        expect(result[:pm10]).to be_nil
      end
    end
  end
end
