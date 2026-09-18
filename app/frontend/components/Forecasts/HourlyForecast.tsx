import { UNIT_LABELS, formatTime, windDirectionLabel, type HourlyForecastEntry, type UnitSystem } from '../../types/forecast'

interface HourlyForecastProps {
  hours: HourlyForecastEntry[]
  units: UnitSystem
}

export default function HourlyForecast({ hours, units }: HourlyForecastProps) {
  if (hours.length === 0) return null

  const labels = UNIT_LABELS[units]

  return (
    <div className="mt-6 min-w-0">
      <h2 className="text-lg font-semibold text-gray-900 mb-2">Hourly forecast</h2>
      <div className="flex gap-3 overflow-x-auto overscroll-x-contain snap-x snap-mandatory pb-2">
        {hours.map((hour) => (
          <div
            key={hour.time}
            className="flex-none w-36 snap-start border border-gray-300 rounded px-3 py-2"
          >
            <p className="text-sm font-medium text-gray-900">{formatTime(hour.time)}</p>
            <p className="text-sm text-gray-600 truncate" title={hour.weather_condition ?? undefined}>
              {hour.weather_condition}
            </p>
            <p className="text-lg text-gray-900">
              {hour.temperature}
              {labels.temperature}
            </p>
            <p className="text-sm text-gray-600">Precip: {hour.precipitation_probability}%</p>
            <p className="text-sm text-gray-600">
              Wind: {hour.wind_speed}
              {labels.wind} {windDirectionLabel(hour.wind_direction)}
            </p>
            <p className="text-sm text-gray-600">
              Gusts: {hour.wind_gusts}
              {labels.wind}
            </p>
          </div>
        ))}
      </div>
    </div>
  )
}
