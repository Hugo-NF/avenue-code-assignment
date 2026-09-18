class ForecastsController < ApplicationController
  UNIT_SYSTEMS = {
    "metric" => { temperature_unit: "celsius", wind_speed_unit: "kmh", precipitation_unit: "mm" },
    "imperial" => { temperature_unit: "fahrenheit", wind_speed_unit: "mph", precipitation_unit: "inch" }
  }.freeze
  DEFAULT_UNITS = "metric"
  HOURLY_HOURS_OPTIONS = [ 12, 24, 48, 72 ].freeze
  DEFAULT_HOURLY_HOURS = 24

  def index
    begin
      forecast = current_forecast
      air_quality = current_air_quality
    rescue Weather::OpenMeteo::Base::ServerError
      forecast = nil
      air_quality = nil
    end

    render inertia: "Forecasts/Index", props: {
      address: session[:address],
      forecast: forecast,
      air_quality: air_quality,
      units: session[:units] || DEFAULT_UNITS,
      hourly_hours: session[:hourly_hours] || DEFAULT_HOURLY_HOURS
    }
  end

  def create
    search = resolve_search_params
    return unless search

    forecast = fetch_forecast(search[:latitude], search[:longitude], **search.slice(:units, :hourly_hours))
    air_quality = fetch_air_quality(search[:latitude], search[:longitude])

    session.update(search.merge(forecast_cache_hit: forecast[:cache_hit], air_quality_cache_hit: air_quality[:cache_hit]))

    redirect_to root_path
  rescue Weather::OpenMeteo::Base::ServerError
    redirect_to root_path, inertia: { errors: { address: "could not fetch the forecast, please try again" } }
  end

  private

  def resolve_search_params
    units = normalize_units(params[:units])
    hourly_hours = normalize_hourly_hours(params[:hourly_hours])

    location =
      if params[:latitude].present? && params[:longitude].present?
        detected_address = params[:detected_address].to_s.strip.presence
        {
          address: detected_address ? session[:address] : nil,
          latitude: params[:latitude].to_f,
          longitude: params[:longitude].to_f,
          detected_address:,
          geocoding_cache_hit: nil
        }
      else
        resolve_address_location(params[:address])
      end
    return unless location

    location.merge(units:, hourly_hours:)
  end

  def resolve_address_location(raw_address)
    address = raw_address.to_s.strip

    if address.blank?
      redirect_to root_path, inertia: { errors: { address: "can't be blank" } }
      return
    end

    geocoded = geocode(address)
    location = geocoded[:data]

    unless location
      redirect_to root_path, inertia: { errors: { address: "could not be found" } }
      return
    end

    detected_address = [ location[:name], location[:country], location[:zip_code] ].compact.join(", ")

    {
      address:,
      latitude: location[:latitude],
      longitude: location[:longitude],
      detected_address:,
      geocoding_cache_hit: geocoded[:cache_hit]
    }
  end

  def geocode(address)
    client = Weather::OpenMeteo::Geocoding.new
    { data: client.search_response(client.search(address)), cache_hit: client.cache_hit }
  end

  def fetch_forecast(latitude, longitude, units:, hourly_hours:)
    client = Weather::OpenMeteo::Forecast.new
    unit_params = UNIT_SYSTEMS.fetch(units)
    forecast = client.fetch_response(
      client.fetch(latitude, longitude,
        temperature_unit: unit_params[:temperature_unit],
        wind_speed_unit: unit_params[:wind_speed_unit],
        precipitation_unit: unit_params[:precipitation_unit],
        forecast_hours: hourly_hours)
    )
    { data: forecast, cache_hit: client.cache_hit, cached_at: client.cached_at }
  end

  def fetch_air_quality(latitude, longitude)
    client = Weather::OpenMeteo::AirQuality.new
    air_quality = client.fetch_response(client.fetch(latitude, longitude))
    { data: air_quality, cache_hit: client.cache_hit, cached_at: client.cached_at }
  end

  def location_known?
    session[:latitude] && session[:longitude]
  end

  def current_forecast
    return nil unless location_known?

    latitude = session[:latitude]
    longitude = session[:longitude]
    forecast = fetch_forecast(latitude, longitude,
      units: session[:units] || DEFAULT_UNITS,
      hourly_hours: session[:hourly_hours] || DEFAULT_HOURLY_HOURS)

    forecast[:data].merge(
      detected_address: session[:detected_address],
      latitude:,
      longitude:,
      coordinates: "#{latitude}, #{longitude}",
      cache_hit: session[:forecast_cache_hit],
      geocoding_cache_hit: session[:geocoding_cache_hit],
      expires_in: expires_in_words(forecast[:cached_at])
    )
  end

  def current_air_quality
    return nil unless location_known?

    air_quality = fetch_air_quality(session[:latitude], session[:longitude])

    air_quality[:data].merge(cache_hit: session[:air_quality_cache_hit], expires_in: expires_in_words(air_quality[:cached_at]))
  end

  def normalize_units(raw)
    return raw if UNIT_SYSTEMS.key?(raw)

    UNIT_SYSTEMS.key?(session[:units]) ? session[:units] : DEFAULT_UNITS
  end

  def normalize_hourly_hours(raw)
    value = raw.presence&.to_i
    return value if HOURLY_HOURS_OPTIONS.include?(value)

    HOURLY_HOURS_OPTIONS.include?(session[:hourly_hours]) ? session[:hourly_hours] : DEFAULT_HOURLY_HOURS
  end

  def expires_in_words(cached_at)
    expires_at = cached_at + Weather::OpenMeteo::Base::CACHE_EXPIRY
    remaining = expires_at - Time.current

    return "expired" if remaining <= 0

    helpers.distance_of_time_in_words(Time.current, expires_at)
  end
end
