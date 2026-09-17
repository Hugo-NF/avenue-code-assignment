import { type FormEvent } from 'react'
import { Head, useForm, usePage } from '@inertiajs/react'

interface Props {
  address: string | null
}

export default function Index({ address }: Props) {
  const { errors } = usePage().props
  const form = useForm({ address: address || '' })

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    form.post('/')
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
        </div>
        <button
          type="submit"
          disabled={form.processing}
          className="rounded bg-gray-900 text-white px-4 py-2"
        >
          Get Forecast
        </button>
      </form>

      {address && (
        <p className="text-gray-600">Looking up the forecast for: {address}</p>
      )}
    </div>
  )
}
