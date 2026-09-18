require "rails_helper"

class WeatherOpenMeteoBaseTestClient < Weather::OpenMeteo::Base
  attr_reader :calls

  def initialize
    @calls = 0
  end

  def call(*args, **kwargs)
    cached_request(:call, *args, **kwargs) do
      @calls += 1
      "result-#{@calls}"
    end
  end
end

RSpec.describe Weather::OpenMeteo::Base do
  subject(:client) { WeatherOpenMeteoBaseTestClient.new }

  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = original_cache
  end

  describe "#cached_request" do
    it "computes the result on the first call" do
      expect(client.call("a", "b")).to eq("result-1")
      expect(client.cache_hit).to be(false)
    end

    it "returns the cached result without recomputing on a repeated call", :aggregate_failures do
      client.call("a", "b")

      expect(client.call("a", "b")).to eq("result-1")
      expect(client.calls).to eq(1)
      expect(client.cache_hit).to be(true)
    end

    it "computes again for a different set of arguments" do
      client.call("a", "b")
      client.call("a", "c")

      expect(client.calls).to eq(2)
    end

    it "uses the fully qualified class and method name as the cache key" do
      client.call("a", "b")

      expect(Rails.cache.exist?("WeatherOpenMeteoBaseTestClient.call(a,b)")).to be(true)
    end

    it "keeps the original cached_at across a cache hit" do
      client.call("a")
      first_cached_at = client.cached_at

      travel 5.minutes
      client.call("a")

      expect(client.cached_at).to eq(first_cached_at)
    end

    it "recomputes after the cache entry expires" do
      client.call("a")

      travel(described_class::CACHE_EXPIRY + 1.minute) do
        client.call("a")
      end

      expect(client.calls).to eq(2)
    end
  end
end
