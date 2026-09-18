require "rails_helper"

RSpec.describe Weather::OpenMeteo::Geocoding do
  subject(:client) { described_class.new }

  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = original_cache
  end

  describe "#search", :vcr do
    context "when the address can be found" do
      it "returns the raw geocoding response" do
        response = client.search("Mountain View, CA")

        expect(response.dig("results", 0, "name")).to eq("Mountain View")
      end
    end

    context "when the address cannot be found" do
      it "returns no results" do
        response = client.search("asdkfjaslkdfjalskdjf")

        expect(response["results"]).to be_nil
      end
    end

    context "when called twice with the same arguments" do
      it "caches the response", :aggregate_failures do
        client.search("Mountain View, CA")
        expect(client.cache_hit).to be(false)

        client.search("Mountain View, CA")
        expect(client.cache_hit).to be(true)
      end
    end

    context "when called with different arguments" do
      it "performs a new request" do
        client.search("Mountain View, CA")
        client.search("Mountain View, CA", language: "es")

        expect(client.cache_hit).to be(false)
      end
    end
  end

  describe "#search_response" do
    context "when there is a result" do
      let(:response) do
        {
          "results" => [
            {
              "latitude" => 37.38605,
              "longitude" => -122.08385,
              "name" => "Mountain View",
              "country" => "United States",
              "postcodes" => %w[94035 94039]
            }
          ]
        }
      end

      it "extracts the first result", :aggregate_failures do
        result = client.search_response(response)

        expect(result[:latitude]).to eq(37.38605)
        expect(result[:longitude]).to eq(-122.08385)
        expect(result[:name]).to eq("Mountain View")
        expect(result[:country]).to eq("United States")
        expect(result[:zip_code]).to eq("94035")
      end
    end

    context "when there are no results" do
      it "returns nil" do
        expect(client.search_response({})).to be_nil
      end
    end

    context "when the result has no postcodes" do
      let(:response) do
        { "results" => [ { "latitude" => 1.0, "longitude" => 2.0, "name" => "X", "country" => "Y" } ] }
      end

      it "returns a nil zip_code" do
        expect(client.search_response(response)[:zip_code]).to be_nil
      end
    end
  end
end
