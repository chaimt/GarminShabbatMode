# Quickstart: Shabbat Time Display

**Feature**: `003-shabbat-time-display`  
**Target**: New developer onboarding or resuming work on the time-display feature

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Garmin Connect IQ SDK | 4.0+ | Download from [developer.garmin.com](https://developer.garmin.com/connect-iq/sdk/) |
| Monkey C Extension | Latest | VS Code extension: `garmin.monkey-c`; or Garmin Eclipse plugin |
| Java (JRE) | 11+ | Required by the Connect IQ SDK build tools |
| macOS / Linux / Windows | Any | SDK supports all three platforms |

---

## 1. Install the Connect IQ SDK

```bash
# macOS: install via the SDK Manager (GUI)
open https://developer.garmin.com/connect-iq/sdk/

# Or download directly and unzip:
unzip connectiq-sdk-mac-*.zip -d ~/garmin-sdk
export CIQ_HOME=~/garmin-sdk
export PATH="$CIQ_HOME/bin:$PATH"
```

Add `CIQ_HOME/bin` to your `PATH` permanently (`.zshrc` / `.bashrc`).

---

## 2. Install Target Device Simulation Profiles

The SDK Manager includes device simulators. Download at minimum:

- **Forerunner 965** (primary test device — feature 002 target)
- **Fenix 7** (secondary — fenix series test)
- **Venu 3** (AMOLED always-on display test)

```bash
# From SDK Manager → Devices → select above devices → Install
```

---

## 3. Clone and Set Up the Repository

```bash
git clone <repo-url>
cd ShabbatMode
git checkout feature/003-shabbat-time-display
```

---

## 4. Build the App

### Using VS Code (recommended)

1. Open the `ShabbatMode/` folder in VS Code
2. Install the **Monkey C** extension (`garmin.monkey-c`)
3. Press `F5` → Select a device profile → The simulator launches automatically

### Using the Command Line

```bash
# Build for Forerunner 965
monkeyc \
  -f monkey.jungle \
  -o bin/ShabbatMode.prg \
  -d fr965 \
  -y developer_key.der \
  -r

# Run in simulator
connectiq &
monkeydo bin/ShabbatMode.prg fr965
```

> **Note**: You need a developer key (`.der` file). Generate one via **VS Code → Monkey C: Generate Developer Key** or `openssl` — see [Garmin docs](https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/).

---

## 5. Project Structure Overview

```text
ShabbatMode/
├── manifest.xml               # App metadata (permissions, target devices)
├── monkey.jungle              # Build manifest (source + resource roots)
├── src/
│   ├── services/SunCalculator.mc    # NOAA solar algorithm (core math)
│   ├── services/AstronomicalService.mc
│   ├── services/ShabbatTimeService.mc
│   ├── services/BatteryConservationService.mc
│   └── ui/MainView.mc               # Root view
└── resources/
    └── strings/
        ├── strings.xml
        ├── shabbat_strings.xml
        └── time_strings.xml
```

Full source layout is documented in `plan.md § Project Structure`.

---

## 6. Key Algorithms — KosherJava Reference

This app implements the same algorithms used by KosherJava (https://kosherjava.com/zmanim-project/) in native Monkey C:

| KosherJava concept | Monkey C file | Details |
|---|---|---|
| `NOAACalculator.getSunrise/Sunset` | `SunCalculator.mc` | NOAA simplified algorithm; zenith 90.8333° |
| `ZmanimCalendar.getCandleLighting()` | `ShabbatTimes.mc` | `sunset − N minutes` (default 18) |
| `ZmanimCalendar.getTzais()` | `ShabbatTimes.mc` | `sunset + N minutes` (default 42) |

Cross-reference: see `research.md § KosherJava Algorithm Cross-Reference Table` for full mapping.

---

## 7. Running Tests

There is no automated test runner in the CIQ SDK. Verification is done via the simulator:

### Calculation Accuracy Test (SC-002: ±2 min)

1. Launch the app in the simulator
2. In the simulator, set a fake GPS location: **GPS → Set Location**
   - Test location: Lakewood, NJ (40.096°N, 74.222°W)
3. Compare displayed sunrise/sunset with [KosherJava Zmanim Calendar](https://kosherjava.com/zmanim-project/zmanim-calendar/) for the same location and today's date
4. **Pass criteria**: displayed times within ±2 minutes of KosherJava reference

### Battery Conservation Mode Test (SC-005: ≥80% refresh reduction)

1. Override the simulated time to Friday after candle lighting
2. Verify in simulator logs: `"BatteryConservation: ACTIVE"` is logged
3. Observe the screen update interval: should be 30 s (vs 1 s normal)
4. Verify `System.DeviceSettings` DND flag is unchanged (SC-007)

### Polar Region Fallback Test

1. Set GPS location to Tromsø, Norway (69.65°N, 18.96°E) in summer
2. App should display "Polar: times unavailable" or equivalent localised string
3. No crash; graceful degradation to time-only display

---

## 8. Common Development Tasks

### Adding a new Shabbat time offset option

1. Add the new default value to `TimeConfiguration.mc`
2. Expose it in `TimeSettingsView.mc` with a new settings menu item
3. Add the settings string to `resources/strings/shabbat_strings.xml`
4. Update `ShabbatTimes.configureFromSunset()` to consume the new offset

### Changing the candle lighting default

Edit `TimeConfiguration.mc`:
```monkeyc
const DEFAULT_CANDLE_LIGHTING_OFFSET = 18; // minutes before sunset
```

### Verifying a calculation against KosherJava

```java
// Java snippet to generate reference value (run standalone with KosherJava jar)
GeoLocation loc = new GeoLocation("Test", 40.096, -74.222, 0,
    TimeZone.getTimeZone("America/New_York"));
ZmanimCalendar zc = new ZmanimCalendar(loc);
System.out.println("Sunset: " + zc.getSunset());
System.out.println("Candles: " + zc.getCandleLighting());
```

Then compare with what the Garmin simulator displays for the same location and date.

---

## 9. Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Times show as "−−:−−" | No GPS fix + empty `LocationCache` | Simulate GPS location in Connect IQ Simulator |
| Sunrise/sunset off by hours | UTC offset not applied | Check `TimezoneService.getUtcOffsetSeconds()` returns correct offset |
| App crashes on startup | Missing resource string key | Check `resources/strings/*.xml` for any key referenced in code but not defined |
| Conservation mode never activates | Simulated date is not Friday/Saturday | Change simulator clock to Friday evening |
| Candle lighting time negative | Sunset − offset underflows midnight | Edge case if sunset is before midnight (polar summer) — not expected at normal latitudes |

---

## 10. References

- [KosherJava Zmanim Project](https://kosherjava.com/zmanim-project/) — Authoritative reference for all zmanim algorithms
- [KosherJava How to Use the API](https://kosherjava.com/zmanim-project/how-to-use-the-zmanim-api/) — Algorithm examples
- [KosherJava Javadoc](https://kosherjava.com/zmanim/docs/api/) — Full API reference
- [NOAA Solar Calculator](https://gml.noaa.gov/grad/solcalc/) — Online reference tool for verifying sunrise/sunset
- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) — Build tools and simulator
- [Monkey C Language Reference](https://developer.garmin.com/connect-iq/reference-guides/monkey-c-reference/) — Language docs
- [Toybox API Reference](https://developer.garmin.com/connect-iq/api-docs/) — `Toybox.Position`, `Toybox.Time`, `Toybox.Math`
