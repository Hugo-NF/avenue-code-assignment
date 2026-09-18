import { HOURLY_HOURS_OPTIONS, UNIT_LABELS, type HourlyHoursOption, type UnitSystem } from '../../types/forecast'

interface UnitsControlProps {
  units: UnitSystem
  hourlyHours: HourlyHoursOption
  disabled: boolean
  onChange: (next: { units: UnitSystem; hourlyHours: HourlyHoursOption }) => void
}

export default function UnitsControl({ units, hourlyHours, disabled, onChange }: UnitsControlProps) {
  return (
    <div className="flex gap-3 mb-6">
      <select
        value={units}
        disabled={disabled}
        onChange={(event) => onChange({ units: event.target.value as UnitSystem, hourlyHours })}
        className="border border-gray-300 rounded px-3 py-2"
      >
        {(Object.keys(UNIT_LABELS) as UnitSystem[]).map((system) => (
          <option key={system} value={system}>
            {UNIT_LABELS[system].name}
          </option>
        ))}
      </select>
      <select
        value={hourlyHours}
        disabled={disabled}
        onChange={(event) => onChange({ units, hourlyHours: Number(event.target.value) as HourlyHoursOption })}
        className="border border-gray-300 rounded px-3 py-2"
      >
        {HOURLY_HOURS_OPTIONS.map((hours) => (
          <option key={hours} value={hours}>
            Next {hours} hours
          </option>
        ))}
      </select>
    </div>
  )
}
