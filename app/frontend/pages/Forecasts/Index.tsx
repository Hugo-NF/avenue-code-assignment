import { useState, type FormEvent } from 'react'
import { Head, router, useForm, usePage } from '@inertiajs/react'
import UnitsControl from '../../components/Forecasts/UnitsControl'
import HourlyForecast from '../../components/Forecasts/HourlyForecast'
import {
  UNIT_LABELS,
  formatTime,
  type AirQuality,
  type Forecast,
  type HourlyHoursOption,
  type UnitSystem,
} from '../../types/forecast'

interface Props {
  address: string | null
  forecast: Forecast | null
  air_quality: AirQuality | null
  units: UnitSystem
  hourly_hours: HourlyHoursOption
}

export default function Index({ address, forecast, air_quality: airQuality, units: appliedUnits, hourly_hours: appliedHourlyHours }: Props) {
  const { errors } = usePage().props
  const form = useForm({ address: address || '' })
  const [locating, setLocating] = useState(false)
  const [locationError, setLocationError] = useState<string | null>(null)
  const [applying, setApplying] = useState(false)
  const [units, setUnits] = useState<UnitSystem>(appliedUnits)
  const [hourlyHours, setHourlyHours] = useState<HourlyHoursOption>(appliedHourlyHours)

  const labels = UNIT_LABELS[appliedUnits]

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()

    if (form.data.address.trim() === '' && forecast) {
      setApplying(true)
      router.post('/', {
        latitude: forecast.latitude,
        longitude: forecast.longitude,
        detected_address: forecast.detected_address,
        units,
        hourly_hours: hourlyHours,
      }, {
        onFinish: () => setApplying(false),
      })
      return
    }

    form.transform((data) => ({ ...data, units, hourly_hours: hourlyHours }))
    form.post('/', {
      onSuccess: () => form.setData('address', ''),
    })
  }

  function handleUseLocation() {
    if (!navigator.geolocation) {
      setLocationError('Geolocation is not supported by this browser')
      return
    }

    setLocating(true)
    setLocationError(null)

    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocating(false)
        const { latitude, longitude } = position.coords
        router.post('/', { latitude, longitude, units, hourly_hours: hourlyHours }, {
          onSuccess: () => form.setData('address', ''),
        })
      },
      (error) => {
        setLocating(false)
        setLocationError(error.message || 'Unable to determine your location')
      }
    )
  }

  function handlePreferencesChange(next: { units: UnitSystem; hourlyHours: HourlyHoursOption }) {
    setUnits(next.units)
    setHourlyHours(next.hourlyHours)
  }

  return (
    <div className="w-full max-w-2xl min-w-0 mx-auto">
      <Head title="Weather Forecast" />

      <h1 className="text-2xl font-semibold text-gray-900 mb-4">Weather Forecast</h1>

      <UnitsControl
        units={units}
        hourlyHours={hourlyHours}
        disabled={form.processing || locating || applying}
        onChange={handlePreferencesChange}
      />

      <form onSubmit={handleSubmit} className="flex items-start gap-3 mb-6">
        <div className="flex-1">
          <input
            type="text"
            placeholder="Enter an address"
            value={form.data.address}
            onChange={(event) => form.setData('address', event.target.value)}
            className="w-full border border-gray-300 rounded px-3 py-2"
          />
          {errors.address && (
            <p className="text-red-600 text-sm mt-1">{errors.address}</p>
          )}
          {locationError && (
            <p className="text-red-600 text-sm mt-1">{locationError}</p>
          )}
        </div>
        <button
          type="submit"
          disabled={form.processing || applying}
          className="rounded bg-gray-900 text-white px-4 py-2"
        >
          Get Forecast
        </button>
        <button
          type="button"
          onClick={handleUseLocation}
          disabled={locating || form.processing || applying}
          className="rounded border border-gray-900 px-4 py-2"
        >
          {locating ? 'Locating…' : 'Use Location'}
        </button>
      </form>

      {forecast && (
        <div>
          {forecast.detected_address && <p>Detected address: {forecast.detected_address}</p>}
          <p>Coordinates: {forecast.coordinates}</p>
          {forecast.cache_hit && <p>(Cached response: expires in {forecast.expires_in})</p>}
          {airQuality?.cache_hit && <p>(Cached response: expires in {airQuality.expires_in})</p>}

          <div className="mt-4">
            <p className="text-3xl text-gray-900">
              {forecast.current_temperature}
              {labels.temperature}
            </p>
            <p>{forecast.weather_condition}</p>
            <p>
              Feels like {forecast.feels_like_temperature}
              {labels.temperature}
            </p>
            <p>
              High: {forecast.high_temperature}
              {labels.temperature} / Low: {forecast.low_temperature}
              {labels.temperature}
            </p>
          </div>

          <div className="mt-4 grid grid-cols-2 gap-x-4 gap-y-1 text-sm text-gray-700">
            <p>Humidity: {forecast.humidity}%</p>
            <p>
              Cloud cover: {forecast.cloud_cover}%
            </p>
            <p>Pressure: {forecast.pressure} hPa</p>
            <p>
              Dew point: {forecast.dew_point}
              {labels.temperature}
            </p>
            <p>
              Visibility: {forecast.visibility} {labels.visibility}
            </p>
            <p>UV index (today's max): {forecast.daily_uv_index_max}</p>
            <p>
              Soil temperature: {forecast.soil_temperature}
              {labels.temperature}
            </p>
            <p>Soil moisture: {forecast.soil_moisture} m³/m³</p>
            <p>Sunrise: {formatTime(forecast.sunrise)}</p>
            <p>Sunset: {formatTime(forecast.sunset)}</p>
          </div>

          {airQuality && (
            <div className="mt-4">
              <h2 className="text-lg font-semibold text-gray-900 mb-1">Air Quality</h2>
              <p>
                US AQI: {airQuality.us_aqi} ({airQuality.us_aqi_category})
              </p>
              <p>PM2.5: {airQuality.pm2_5} µg/m³ / PM10: {airQuality.pm10} µg/m³</p>
            </div>
          )}

          {forecast.dates.length > 0 && (
            <div className="mt-6 min-w-0">
              <h2 className="text-lg font-semibold text-gray-900 mb-2">Daily forecast</h2>
              <div className="flex gap-3 overflow-x-auto overscroll-x-contain snap-x snap-mandatory pb-2">
                {forecast.dates.map((date, index) => (
                  <div key={date} className="flex-none w-28 snap-start border border-gray-300 rounded px-3 py-2">
                    <p className="text-sm font-medium text-gray-900">{date}</p>
                    <p className="text-sm text-gray-600">
                      H: {forecast.daily_highs[index]}
                      {labels.temperature}
                    </p>
                    <p className="text-sm text-gray-600">
                      L: {forecast.daily_lows[index]}
                      {labels.temperature}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          )}

          <HourlyForecast hours={forecast.hourly_forecast} units={appliedUnits} />
        </div>
      )}
    </div>
  )
}
