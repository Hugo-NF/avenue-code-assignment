import { useState, type FormEvent } from 'react'
import { Head, router, useForm, usePage } from '@inertiajs/react'

interface Forecast {
  detected_address: string | null
  coordinates: string
  current_temperature: number
  high_temperature: number
  low_temperature: number
  daily_highs: number[]
  daily_lows: number[]
  dates: string[]
  cache_hit: boolean
  geocoding_cache_hit: boolean | null
  expires_in: string
}

interface Props {
  address: string | null
  forecast: Forecast | null
}

export default function Index({ address, forecast }: Props) {
  const { errors } = usePage().props
  const form = useForm({ address: address || '' })
  const [locating, setLocating] = useState(false)
  const [locationError, setLocationError] = useState<string | null>(null)

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
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
        router.post('/', { latitude, longitude }, {
          onSuccess: () => form.setData('address', ''),
        })
      },
      (error) => {
        setLocating(false)
        setLocationError(error.message || 'Unable to determine your location')
      }
    )
  }

  return (
    <div className="w-full max-w-xl mx-auto">
      <Head title="Weather Forecast" />

      <h1 className="text-2xl font-semibold text-gray-900 mb-4">Weather Forecast</h1>

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
          disabled={form.processing}
          className="rounded bg-gray-900 text-white px-4 py-2"
        >
          Get Forecast
        </button>
        <button
          type="button"
          onClick={handleUseLocation}
          disabled={locating || form.processing}
          className="rounded border border-gray-900 px-4 py-2"
        >
          {locating ? 'Locating…' : 'Use Location'}
        </button>
      </form>

      {forecast && (
        <div>
          {forecast.detected_address && <p>Detected address: {forecast.detected_address}</p>}
          <p>Coordinates: {forecast.coordinates}</p>
          <p>Current: {forecast.current_temperature}°C</p>
          <p>High: {forecast.high_temperature}°C / Low: {forecast.low_temperature}°C</p>
          {forecast.cache_hit && <p>(Cached response: expires in {forecast.expires_in})</p>}
        </div>
      )}
    </div>
  )
}
