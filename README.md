# ShabbatMode

A Garmin Connect IQ widget that displays Shabbat and Jewish holiday times directly on your Garmin device. The app uses your device's GPS to calculate accurate candle lighting, sunrise, sunset, and end-of-Shabbat times for your current location.

## Features

- **Real-time clock** — current time displayed with 1-second updates
- **Astronomical times** — GPS-based sunrise and sunset calculations accurate to ±2 minutes
- **Candle lighting time** — configurable minutes before sunset (default: 18 minutes)
- **End of Shabbat (Havdalah)** — configurable minutes after nightfall (default: 25–42 minutes)
- **Location caching** — GPS coordinates and daily calculations are cached to save battery
- **Graceful degradation** — falls back to cached or approximate times when GPS is unavailable
- **Persistent settings** — user preferences survive restarts

## Supported Devices

| Device       |
|--------------|
| Fenix 6      |
| Fenix 7      |
| Forerunner 965 |
| Venu 2       |
| Epix         |

Additional devices can be added in `manifest.xml`.

## Requirements

| Tool | Version |
|------|---------|
| [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) | 4.0.0+ |
| [Task](https://taskfile.dev) | 3.x |
| Garmin developer key (`~/.Garmin/ConnectIQ/developer_key.der`) | — |

The SDK manager must be installed and a current SDK selected via the Connect IQ SDK manager (the active path is read from `~/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg`).

## Project Structure

```
ShabbatMode/
├── manifest.xml              # App metadata, permissions, and device targets
├── monkey.jungle             # Build configuration (auto-generated, gitignored)
├── Taskfile.yml              # Build task definitions
├── src/
│   ├── models/               # Data models (Location, TimeInfo, ShabbatTimes, AstronomicalData, …)
│   ├── services/             # Business logic services
│   │   ├── LocationService   # GPS acquisition and location management
│   │   ├── AstronomicalService  # Sunrise/sunset calculation engine
│   │   ├── ShabbatTimeService   # Candle lighting and end-of-Shabbat times
│   │   ├── ShabbatWindowService # Active Shabbat window detection and countdown
│   │   ├── TimezoneService   # Timezone detection and DST handling
│   │   ├── TimeService       # Real-time clock management
│   │   └── ConfigService     # Persistent configuration storage
│   ├── ui/
│   │   ├── MainView          # Root application view
│   │   ├── TimeDisplayView   # Primary time display screen
│   │   ├── TimeSettingsView  # User-configurable time preferences
│   │   └── components/
│   │       ├── ClockComponent        # Current time widget
│   │       ├── SunTimesComponent     # Sunrise/sunset display widget
│   │       └── ShabbatTimesComponent # Candle lighting / Havdalah widget
│   ├── lib/
│   │   ├── calculations/     # Pure math utilities (DateMath, SunPosition)
│   │   ├── formatters/       # String formatters (TimeFormatter, DateFormatter)
│   │   ├── validators/       # Input validators (LocationValidator)
│   │   ├── logging/          # Logger
│   │   ├── storage/          # StorageManager (persistent key-value store)
│   │   └── ErrorHandler      # Centralised error handling
│   └── cache/
│       ├── LocationCache     # Cached GPS coordinates
│       └── CalculationCache  # Cached daily astronomical results
├── resources/
│   ├── layouts/              # XML screen layouts
│   ├── strings/              # Localized strings
│   ├── images/               # Drawables and icons
│   └── drawables/            # App launcher icon
├── tests/                    # Unit tests
└── specs/                    # Feature specifications and implementation plans
    ├── 001-base-application/
    └── 003-shabbat-time-display/
```

## Building

### Generate the jungle file and compile

```bash
# Build for the default device (fenix7)
task build

# Build for a specific device
task build DEVICE=fenix6
```

### Run in the simulator

```bash
# Launch the Connect IQ simulator, build, and deploy (all-in-one)
task run

# Or step by step:
task simulator   # opens ConnectIQ.app
task deploy      # builds and sends to the running simulator
```

### Run tests

```bash
task test
```

### Clean build artifacts

```bash
task clean
```

Run `task` (no arguments) to list all available tasks.

## Configuration

Shabbat times are calculated from local sunset using two configurable offsets:

| Setting | Default | Description |
|---------|---------|-------------|
| Candle lighting offset | 18 minutes | Minutes **before** sunset |
| End of Shabbat offset | 42 minutes | Minutes **after** nightfall |

These can be changed from the **TimeSettingsView** inside the app. Settings are saved immediately and persist across restarts.

## Architecture

The app follows a layered service architecture:

```
UI Layer  →  Services  →  Models / Lib  →  Device APIs
```

- **UI** views and components are passive — they request data from services and render it.
- **Services** encapsulate all business logic and call into Garmin device APIs.
- **Models** are plain data classes with no side effects.
- **Lib** contains stateless utility functions (calculations, formatting, validation).
- **Cache** layer sits between services and storage to reduce GPS polling and CPU-intensive calculations.

All astronomical calculations use the standard sunrise equation and are accurate to within ±2 minutes compared to published astronomical references. Daily results are cached so GPS is only queried when the cached location is stale.

## Permissions

The app requests a single device permission:

| Permission | Reason |
|------------|--------|
| `Positioning` | Required to obtain GPS coordinates for location-based astronomical calculations |

## Development

Feature specifications live in `specs/` and follow the Agentic SDLC workflow. Each feature directory contains:

- `spec.md` — user stories, acceptance criteria, and requirements
- `plan.md` — technical design and architecture decisions
- `tasks.md` — ordered implementation checklist with completion status

To add support for a new Garmin device, add a `<iq:product id="..."/>` entry in `manifest.xml`.

## License

This project is personal / private software. All rights reserved.
