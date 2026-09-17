import { useState, type FormEvent } from 'react'
import { Head, useForm, usePage } from '@inertiajs/react'

interface Props {
  address: string | null
}

export default function Index({ address }: Props) {
  const { errors } = usePage().props
  const form = useForm({ address: address || '' })
  const [locating, setLocating] = useState(false)
  const [locationError, setLocationError] = useState<string | null>(null)

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    form.post('/')
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
        form.setData('address', `${latitude},${longitude}`)
        form.post('/')
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

      {address && (
        <p className="text-gray-600">Looking up the forecast for: {address}</p>
      )}
    </div>
  )
}
