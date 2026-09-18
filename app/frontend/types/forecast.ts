export type UnitSystem = 'metric' | 'imperial'
export type HourlyHoursOption = 12 | 24 | 48 | 72

export interface HourlyForecastEntry {
  time: string
  temperature: number | null
  precipitation: number | null
  precipitation_probability: number | null
  wind_speed: number | null
  wind_gusts: number | null
  wind_direction: number | null
  weather_condition: string | null
  dew_point: number | null
  cloud_cover: number | null
  pressure: number | null
  visibility: number | null
  uv_index: number | null
  soil_temperature: number | null
  soil_moisture: number | null
}

export interface Forecast {
  detected_address: string | null
  coordinates: string
  latitude: number
  longitude: number
  current_temperature: number | null
  feels_like_temperature: number | null
  humidity: number | null
  weather_condition: string | null
  cloud_cover: number | null
  pressure: number | null
  dew_point: number | null
  visibility: number | null
  soil_temperature: number | null
  soil_moisture: number | null
  high_temperature: number | null
  low_temperature: number | null
  daily_highs: number[]
  daily_lows: number[]
  dates: string[]
  sunrise: string | null
  sunset: string | null
  daily_uv_index_max: number | null
  hourly_forecast: HourlyForecastEntry[]
  cache_hit: boolean
  geocoding_cache_hit: boolean | null
  expires_in: string
}

export interface AirQuality {
  us_aqi: number | null
  us_aqi_category: string | null
  european_aqi: number | null
  pm2_5: number | null
  pm10: number | null
  cache_hit: boolean
  expires_in: string
}

interface UnitLabelSet {
  temperature: string
  wind: string
  precipitation: string
  visibility: string
  name: string
}

export const UNIT_LABELS: Record<UnitSystem, UnitLabelSet> = {
  metric: { temperature: '°C', wind: 'km/h', precipitation: 'mm', visibility: 'm', name: 'Metric' },
  imperial: { temperature: '°F', wind: 'mph', precipitation: 'in', visibility: 'ft', name: 'Imperial' },
}

export const HOURLY_HOURS_OPTIONS: HourlyHoursOption[] = [12, 24, 48, 72]

const WIND_DIRECTIONS = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']

export function formatTime(iso: string | null): string {
  if (!iso) return '—'
  return iso.slice(11, 16)
}

export function windDirectionLabel(degrees: number | null): string {
  if (degrees === null || degrees === undefined) return ''
  return WIND_DIRECTIONS[Math.round(degrees / 45) % 8]
}
