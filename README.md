# Avenue Code Assignment

## Problem statement

Build a small web app that:

- Accepts an address as input.
- Looks up the current weather forecast for that address (minimum: current
  temperature; bonus: high/low and/or an extended forecast).
- Displays the forecast to the user.
- Caches forecast results for 30 minutes per lookup, so repeated requests
  for the same place don't hit the weather API again.
- Shows an indicator when a result came from the cache.

## How to run

### Locally (Docker)

The Dockerfile builds a production image, which needs a `SECRET_KEY_BASE`
to boot (used to sign/encrypt sessions). Rails reads it straight from the
`SECRET_KEY_BASE` env var if present, before it would ever fall back to
`config/master.key`/`config/credentials.yml.enc`, so there's no need to
touch Rails credentials, or even have Ruby installed, to run this. Generate
any random value and pass it in at `docker run`:

```bash
docker build -t avenue_assignment .
docker run -d -p 3000:80 -e SECRET_KEY_BASE=$(openssl rand -hex 64) --name avenue_assignment avenue_assignment
```

The app is served at `http://localhost:3000`.

### Locally

Requirements:

- Ruby 4.0.6
- Node.js 22
- pnpm 10.28.2

[mise](https://mise.jdx.dev) is a good way to install and pin these
versions if you don't already have them, and it's what I've been using on
my machines for years now.

```bash
bundle install
pnpm install
bin/setup
```

`bin/setup` prepares the database and starts `bin/dev`, which runs the
Rails server, the Tailwind watcher, and the Vite dev server together
(`Procfile.dev`).

**NOTE:** I thought of doing a deployed version of this app on AWS - it
would be an improvement and would also make things easier for the person
evaluating this test. But I backed off from that idea, because the
assessment guide explicitly asks not to upload the assessment online, and
I wasn't sure if that would disqualify me. The PDF guides are also not on the repo for the exact same reason.

## Technologies used and rationale

- **Ruby on Rails 8:**  application framework.
- **SQLite** + **Solid Cache:**  datastore and the database-backed cache
  store used to satisfy the 30-minute caching requirement. This choice
  avoided the need for extra services/infrastructure (Redis/Memcached),
  with the added benefit that Solid Cache is the new Rails standard since
  version 8.
- **Inertia Rails** + **React** + **TypeScript:**  I chose Inertia because I wanted a simpler setup for
  this project. Since this is a single interactive page (address in,
  forecast out), a small client-rendered component gave a snappier
  form/result experience than full-page reloads, while Inertia kept
  routing, sessions, and validation entirely server-side. There was no
  need to design a Rails API and a separate React application, which was
  what I wanted to avoid the most due to time restrictions.
- **pnpm:**  Replaced npm with pnpm for convenience, since it's what I've
  been using lately.
- **Tailwind CSS** styling. Nothing special about
  it; could be any other styling library.
- **RSpec** + **VCR** + **WebMock:**  test suite; external Open-Meteo calls
  are recorded as cassettes so the suite is fast and deterministic, since
  we don't do real network calls during test execution. I find `vcr` more
  practical to use than writing/maintaining mocks in other ways.
- **SimpleCov** + **octocov:**  coverage measurement and PR reporting.
- **RuboCop**, **Brakeman**, **bundler-audit:** 
  follow Rails standards, no changes here.
- **Open-Meteo:**  the weather provider: free and without API keys, which
  kept setup friction at zero for anyone running this locally, and it also
  provided a geocoding API. Since the geocoding API wasn't reliably giving
  good results for addresses outside the US, I added the option to request
  the browser's location permission instead. I'll try to improve on this
  and add a better map provider if I have time to do so. Both calls
  (geocoding and weather) are cached: a repeated address skips both
  external calls, and a new address that geocodes to the same place still
  gets a fresh geocoding cache miss but a forecast cache hit. This is a
  deliberate interpretation of "per zip code" broadened to "per resolved
  location," since the input isn't guaranteed to be a ZIP code.

## Extras

Beyond the core requirements, the repo has a GitHub Actions CI pipeline
(`.github/workflows/ci.yml`) that runs on every pull request and on push
to `master`, with four parallel jobs:

- **scan_ruby:**  Brakeman static analysis + `bundler-audit` for known gem
  vulnerabilities.
- **scan_js:**  `pnpm audit` for JS dependency vulnerabilities + a
  TypeScript type-check.
- **lint:**  RuboCop (Omakase style), with caching between runs.
- **test:**  the RSpec suite, with SimpleCov measuring coverage and
  **octocov** posting a coverage report as a PR comment, gated at a 90%
  minimum.

Dependabot is configured to open weekly PRs for both Bundler and GitHub
Actions dependency updates.

## What could I've done next with more time

- **Add frontend/e2e tests**: `capybara` and `selenium-webdriver` are
  already in the test group but unused , there are currently no system
  specs, only request and lib specs.
- **Richer error handling**: Open-Meteo failures currently collapse into
  one generic "could not fetch the forecast" message; retries/backoff and
  more specific error states (e.g. rate-limited vs. unreachable) would be
  a natural next step.
- **Improve geocoding for addresses outside the US**: add a map with
  better geocoding for addresses worldwide and improved overall
  interactivity.
- **Explore more of the Weather API**: show a multi-day forecast view
  (daily highs/lows over the coming days) instead of just the current
  temperature and today's high/low, and surface other Open-Meteo
  data points, like precipitation and wind.
