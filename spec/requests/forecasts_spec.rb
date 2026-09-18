require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  around do |example|
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
    Rails.cache = original_cache
  end

  describe "GET /" do
    it "renders the forecast page with no address or forecast" do
      get root_path

      expect(inertia).to render_component("Forecasts/Index")
      expect(inertia).to have_props(address: nil, forecast: nil)
    end
  end

  describe "POST /" do
    context "with a blank address" do
      it "redirects with a validation error" do
        post root_path, params: { address: "  " }

        expect(response).to redirect_to(root_path)

        follow_redirect!
        expect(inertia).to have_props(errors: { address: "can't be blank" })
      end
    end

    context "with an address that can be geocoded", :vcr do
      it "stores the forecast in the session on the first request", :aggregate_failures do
        post root_path, params: { address: "Mountain View, CA" }

        expect(response).to redirect_to(root_path)
        expect(session[:address]).to eq("Mountain View, CA")
        expect(session[:forecast][:detected_address]).to eq("Mountain View, United States")
        expect(session[:forecast][:coordinates]).to eq("37.38605, -122.08385")
        expect(session[:forecast][:current_temperature]).to be_present
        expect(session[:forecast][:cache_hit]).to be(false)
        expect(session[:forecast][:geocoding_cache_hit]).to be(false)
        expect { Time.zone.parse(session[:forecast][:cached_at]) }.not_to raise_error
      end

      it "marks the result as cached on a repeated request", :aggregate_failures do
        post root_path, params: { address: "Mountain View, CA" }
        post root_path, params: { address: "Mountain View, CA" }

        expect(session[:forecast][:cache_hit]).to be(true)
        expect(session[:forecast][:geocoding_cache_hit]).to be(true)
      end

      it "shows how long until the cache entry expires" do
        post root_path, params: { address: "Mountain View, CA" }
        follow_redirect!

        expect(inertia.props[:forecast][:expires_in]).to match(/\d+ minutes?/)
      end

      it "shows the entry as expired once the cache window has passed" do
        post root_path, params: { address: "Mountain View, CA" }

        travel(Weather::OpenMeteo::Base::CACHE_EXPIRY + 1.minute) do
          get root_path

          expect(inertia.props[:forecast][:expires_in]).to eq("expired")
        end
      end
    end

    context "with an address that cannot be geocoded", :vcr do
      it "redirects with a validation error" do
        post root_path, params: { address: "asdkfjaslkdfjalskdjf" }

        follow_redirect!
        expect(inertia).to have_props(errors: { address: "could not be found" })
      end
    end

    context "with latitude and longitude params", :vcr do
      it "skips geocoding entirely", :aggregate_failures do
        post root_path, params: { latitude: 37.38605, longitude: -122.08385 }

        expect(session[:address]).to be_nil
        expect(session[:forecast][:detected_address]).to be_nil
        expect(session[:forecast][:coordinates]).to eq("37.38605, -122.08385")
        expect(session[:forecast][:current_temperature]).to be_present
        expect(session[:forecast][:cache_hit]).to be(false)
        expect(session[:forecast][:geocoding_cache_hit]).to be_nil
      end

      it "marks the forecast as cached on a repeated request" do
        post root_path, params: { latitude: 37.38605, longitude: -122.08385 }
        post root_path, params: { latitude: 37.38605, longitude: -122.08385 }

        expect(session[:forecast][:cache_hit]).to be(true)
      end
    end

    context "when the forecast API returns an error", :vcr do
      it "redirects with a generic error" do
        post root_path, params: { latitude: 999, longitude: 999 }

        follow_redirect!
        expect(inertia).to have_props(errors: { address: "could not fetch the forecast, please try again" })
      end
    end
  end
end
