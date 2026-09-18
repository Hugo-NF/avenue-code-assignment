class ForecastsController < ApplicationController
  def index
    render inertia: "Forecasts/Index", props: {
      address: session[:address],
      forecast: session[:forecast] && session[:forecast].merge(expires_in: expires_in_words)
    }
  end

  def create
    if params[:latitude].present? && params[:longitude].present?
      latitude = params[:latitude].to_f
      longitude = params[:longitude].to_f
      address = nil
      detected_address = nil
      geocoding_cache_hit = nil
    else
      address = params[:address].to_s.strip

      if address.blank?
        redirect_to root_path, inertia: { errors: { address: "can't be blank" } }
        return
      end

      location, geocoding_cache_hit = geocode(address)

      unless location
        redirect_to root_path, inertia: { errors: { address: "could not be found" } }
        return
      end

      latitude = location[:latitude]
      longitude = location[:longitude]
      detected_address = [ location[:name], location[:country] ].compact.join(", ")
    end

    forecast, forecast_cache_hit, forecast_cached_at = fetch_forecast(latitude, longitude)

    session[:address] = address
    session[:forecast] = forecast.merge(
      detected_address: detected_address,
      coordinates: "#{latitude}, #{longitude}",
      cache_hit: forecast_cache_hit,
      geocoding_cache_hit: geocoding_cache_hit,
      cached_at: forecast_cached_at.iso8601
    )

    redirect_to root_path
  rescue Weather::OpenMeteo::Base::ServerError
    redirect_to root_path, inertia: { errors: { address: "could not fetch the forecast, please try again" } }
  end

  private

  def geocode(address)
    client = Weather::OpenMeteo::Geocoding.new
    location = client.search_response(client.search(address))
    [ location, client.cache_hit ]
  end

  def fetch_forecast(latitude, longitude)
    client = Weather::OpenMeteo::Forecast.new
    forecast = client.fetch_response(client.fetch(latitude, longitude))
    [ forecast, client.cache_hit, client.cached_at ]
  end

  def expires_in_words
    cached_at = Time.zone.parse(session[:forecast].with_indifferent_access[:cached_at])
    expires_at = cached_at + Weather::OpenMeteo::Base::CACHE_EXPIRY
    remaining = expires_at - Time.current

    return "expired" if remaining <= 0

    helpers.distance_of_time_in_words(Time.current, expires_at)
  end
end
