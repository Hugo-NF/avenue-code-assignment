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
      expect(inertia).to have_props(address: nil, forecast: nil, air_quality: nil, units: "metric", hourly_hours: 24)
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
      it "stores only the search identifiers in the session and renders the forecast on the next request", :aggregate_failures do
        post root_path, params: { address: "Mountain View, CA" }

        expect(response).to redirect_to(root_path)
        expect(session[:address]).to eq("Mountain View, CA")
        expect(session[:detected_address]).to eq("Mountain View, United States")
        expect(session[:latitude]).to eq(37.38605)
        expect(session[:longitude]).to eq(-122.08385)
        expect(session[:geocoding_cache_hit]).to be(false)
        expect(session[:units]).to eq("metric")
        expect(session[:hourly_hours]).to eq(24)
        expect(session).not_to have_key(:forecast)
        expect(session).not_to have_key(:air_quality)

        follow_redirect!

        expect(inertia.props[:forecast][:detected_address]).to eq("Mountain View, United States")
        expect(inertia.props[:forecast][:coordinates]).to eq("37.38605, -122.08385")
        expect(inertia.props[:forecast][:current_temperature]).to be_present
        expect(inertia.props[:forecast][:cache_hit]).to be(false)
        expect(inertia.props[:forecast][:geocoding_cache_hit]).to be(false)
        expect(inertia.props[:air_quality][:us_aqi]).to be_present
        expect(inertia.props[:air_quality][:cache_hit]).to be(false)
      end

      it "marks the result as cached on a repeated request", :aggregate_failures do
        post root_path, params: { address: "Mountain View, CA" }
        post root_path, params: { address: "Mountain View, CA" }

        expect(session[:geocoding_cache_hit]).to be(true)
        expect(session[:forecast_cache_hit]).to be(true)
        expect(session[:air_quality_cache_hit]).to be(true)
      end

      it "shows how long until the cache entry expires", :aggregate_failures do
        post root_path, params: { address: "Mountain View, CA" }
        follow_redirect!

        expect(inertia.props[:forecast][:expires_in]).to match(/\d+ minutes?/)
        expect(inertia.props[:air_quality][:expires_in]).to match(/\d+ minutes?/)
      end

      it "fetches a fresh forecast once the cache window has passed instead of showing stale data", :aggregate_failures do
        post root_path, params: { address: "Mountain View, CA" }

        travel(Weather::OpenMeteo::Base::CACHE_EXPIRY + 1.minute) do
          get root_path

          expect(inertia.props[:forecast][:expires_in]).to match(/\d+ minutes?/)
          expect(inertia.props[:air_quality][:expires_in]).to match(/\d+ minutes?/)
        end
      end

      it "stores the requested units and hourly window", :aggregate_failures do
        post root_path, params: { address: "Mountain View, CA", units: "imperial", hourly_hours: 48 }
        follow_redirect!

        expect(session[:units]).to eq("imperial")
        expect(session[:hourly_hours]).to eq(48)
        expect(inertia.props[:forecast][:hourly_forecast].size).to eq(48)
      end

      it "falls back to the default units for an invalid value" do
        post root_path, params: { address: "Mountain View, CA", units: "bogus" }

        expect(session[:units]).to eq("metric")
      end

      it "falls back to the default hourly window for an invalid value" do
        post root_path, params: { address: "Mountain View, CA", hourly_hours: "999" }

        expect(session[:hourly_hours]).to eq(24)
      end

      it "keeps the previously selected units when not resent", :aggregate_failures do
        post root_path, params: { address: "Mountain View, CA", units: "imperial" }
        post root_path, params: { address: "Mountain View, CA" }

        expect(session[:units]).to eq("imperial")
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
        expect(session[:detected_address]).to be_nil
        expect(session[:latitude]).to eq(37.38605)
        expect(session[:longitude]).to eq(-122.08385)
        expect(session[:geocoding_cache_hit]).to be_nil

        follow_redirect!

        expect(inertia.props[:forecast][:coordinates]).to eq("37.38605, -122.08385")
        expect(inertia.props[:forecast][:current_temperature]).to be_present
        expect(inertia.props[:forecast][:cache_hit]).to be(false)
        expect(inertia.props[:forecast][:geocoding_cache_hit]).to be_nil
      end

      it "marks the forecast as cached on a repeated request" do
        post root_path, params: { latitude: 37.38605, longitude: -122.08385 }
        post root_path, params: { latitude: 37.38605, longitude: -122.08385 }

        expect(session[:forecast_cache_hit]).to be(true)
      end

      it "preserves the address and detected address when a detected_address is passed through", :aggregate_failures do
        post root_path, params: { address: "Mountain View, CA" }
        post root_path, params: {
          latitude: 37.38605, longitude: -122.08385,
          detected_address: "Mountain View, United States", units: "imperial"
        }

        expect(session[:address]).to eq("Mountain View, CA")
        expect(session[:detected_address]).to eq("Mountain View, United States")
        expect(session[:units]).to eq("imperial")
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
