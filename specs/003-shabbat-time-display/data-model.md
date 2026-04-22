# Data Model: Shabbat Time Display

**Feature**: `003-shabbat-time-display`  
**Date**: 2026-04-22

---

## Entities

### 1. `TimeInfo`
**File**: `src/models/TimeInfo.mc`  
**Purpose**: Snapshot of the current wall-clock time in local timezone.

| Field | Type | Description |
|-------|------|-------------|
| `hour` | `Number` | Local hour (0–23) |
| `minute` | `Number` | Local minute (0–59) |
| `second` | `Number` | Local second (0–59) |
| `is24Hour` | `Boolean` | Display in 24h format |

**Validation**: Hour ∈ [0,23], Minute ∈ [0,59], Second ∈ [0,59].  
**State Transitions**: Updated every 1 second (normal) or 30 seconds (Shabbat conservation mode) via `TimeService`.

---

### 2. `Location`
**File**: `src/models/Location.mc`  
**Purpose**: Geographic coordinates used as input to astronomical calculations.

| Field | Type | Description |
|-------|------|-------------|
| `latitude` | `Float` | Degrees North (+) / South (−), range [−90, 90] |
| `longitude` | `Float` | Degrees East (+) / West (−), range [−180, 180] |
| `isValid` | `Boolean` | True when coordinates have been successfully acquired |

**Validation**: `LocationValidator.isPolarRegion(lat)` → true when `|lat| > 66.5°` (astronomical calculations unreliable above Arctic/Antarctic circles).  
**Persistence**: Stored to `Application.Storage` via `LocationCache` so the app can start without an immediate GPS fix.  
**Source**: `Toybox.Position.getInfo()` or `Application.Storage` (fallback).

---

### 3. `AstronomicalData`
**File**: `src/models/AstronomicalData.mc`  
**Purpose**: Sunrise and sunset times for a specific day and location, computed by `AstronomicalService` using the NOAA algorithm (same as KosherJava `NOAACalculator`).

| Field | Type | Description |
|-------|------|-------------|
| `latitude` | `Float` | Location latitude used for this calculation |
| `longitude` | `Float` | Location longitude used for this calculation |
| `dayId` | `Number` | `DateMath.todayDayId()` — unique integer per calendar day |
| `sunriseLocalSeconds` | `Number` | Seconds since local midnight for sunrise; −1 = unavailable |
| `sunsetLocalSeconds` | `Number` | Seconds since local midnight for sunset; −1 = unavailable |
| `isPolarRegion` | `Boolean` | True when sunrise/sunset are not computable |

**Computed by**: `SunCalculator.calculateSunsetUTC()` and `AstronomicalService._calculateSunriseUTC()` — NOAA simplified solar position algorithm (zenith = 90.8333°).  
**Cache key**: `dayId` — invalidated on day rollover. Stored in `CalculationCache` (in-memory, not persistent).  
**KosherJava equivalents**: `ZmanimCalendar.getSunrise()`, `ZmanimCalendar.getSunset()`.

---

### 4. `ShabbatTimes`
**File**: `src/models/ShabbatTimes.mc`  
**Purpose**: Derived Shabbat-specific times computed from `AstronomicalData` sunset plus configurable offsets.

| Field | Type | Description |
|-------|------|-------------|
| `candleLightingLocalSeconds` | `Number` | Local seconds of candle lighting time; −1 = unavailable |
| `shabbatEndLocalSeconds` | `Number` | Local seconds of end of Shabbat (tzais); −1 = unavailable |
| `dayId` | `Number` | Calendar day for which these times are valid |

**Computation**:
- `candleLighting = sunsetLocalSeconds − (candleLightingOffset × 60)`  
  Default: 18 min before sunset. KosherJava equivalent: `ZmanimCalendar.getCandleLighting()`.
- `shabbatEnd = sunsetLocalSeconds + (shabbatEndOffset × 60)`  
  Default: 42 min after sunset (Rabbeinu Tam, common Ashkenazic custom). KosherJava equivalent: `ZmanimCalendar.getTzais()` at the 42-minute opinion.

**Validation**: If `sunsetLocalSeconds == −1`, both derived times are also −1 (no valid sunset → no valid Shabbat times).  
**Configured by**: `TimeConfiguration`.

---

### 5. `TimeConfiguration`
**File**: `src/models/TimeConfiguration.mc`  
**Purpose**: User-configurable preferences for time offsets and display format.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `candleLightingOffsetMinutes` | `Number` | 18 | Minutes before sunset for candle lighting |
| `shabbatEndOffsetMinutes` | `Number` | 42 | Minutes after sunset for end of Shabbat (tzais) |
| `rabbenuTamEnabled` | `Boolean` | false | If true, adds 16.1° zenith-based tzais (future capability) |
| `use24HourFormat` | `Boolean` | true | Whether to display time in 24h format |

**Persistence**: Stored to `Application.Storage` via `ConfigService`.  
**Accepted ranges**: `candleLightingOffsetMinutes` ∈ [10, 60]; `shabbatEndOffsetMinutes` ∈ [20, 90].  
**KosherJava analogy**: `ZmanimCalendar.setCandleLightingOffset(int offset)` and the caller choosing a specific tzais method.

---

### 6. `BatteryConservationState` (implicit in `BatteryConservationService`)

No separate model class — state is held inside `BatteryConservationService`.

| Conceptual Field | Type | Description |
|-----------------|------|-------------|
| `isActive` | `Boolean` | True during Shabbat window |
| `refreshIntervalMs` | `Number` | 1000 (normal) or 30000 (conservation) |
| `gpsIntervalSeconds` | `Number` | 300 (5 min, normal) or 1800 (30 min, conservation) |

**Transition trigger**: `ShabbatWindowService.isShabbat()` — checked on every timer tick via `BatteryConservationService.update()`.  
**Side effects on activation**: `LocationService.setUpdateIntervalSeconds(1800)`.  
**Side effects on deactivation**: `LocationService.setUpdateIntervalSeconds(300)`; `MainView` restarts timer at 1000ms.

---

## Entity Relationships

```text
TimeConfiguration ──────────── ShabbatTimeService
                                      │
                          ┌───────────┴──────────┐
                          │                      │
                   AstronomicalService     ShabbatWindowService
                          │
                   AstronomicalData
                      (cached by dayId)
                          │
              ┌───────────┴──────────┐
              │                      │
       sunriseLocalSecs       sunsetLocalSecs
              │                      │
       SunTimesComponent      ShabbatTimes ← TimeConfiguration
                                    │
                        ┌───────────┴──────────┐
                        │                      │
               candleLightingLocalSecs  shabbatEndLocalSecs
                        │                      │
                ShabbatTimesComponent   ShabbatTimesComponent


LocationService ── LocationCache (Application.Storage)
      │
   Location
      │
AstronomicalService (consumes lat/lon)

BatteryConservationService ── ShabbatWindowService
      │
      ├── getRefreshIntervalMs() → MainView timer interval
      └── getGpsIntervalSeconds() → LocationService poll interval
```

---

## Calculation Pipeline

```
GPS Fix
  └─→ Location (lat, lon)
        └─→ SunCalculator.calculateSunsetUTC(lat, lon, n)       [NOAA algorithm]
              └─→ AstronomicalService → AstronomicalData
                    ├─→ sunriseLocalSecs (displayed in SunTimesComponent)
                    └─→ sunsetLocalSecs
                          └─→ ShabbatTimeService → ShabbatTimes
                                ├─→ candleLightingLocalSecs     [sunset − candleOffset]
                                └─→ shabbatEndLocalSecs         [sunset + endOffset]
```

---

## Notes on KosherJava Alignment

The data model closely mirrors KosherJava's class hierarchy:

- `AstronomicalData` ≈ KosherJava `AstronomicalCalendar` (holds location + computed times for one day)
- `ShabbatTimes` ≈ KosherJava `ZmanimCalendar` (adds candle lighting + tzais to the astronomical base)
- `TimeConfiguration` ≈ KosherJava `GeoLocation` + caller-supplied offset parameters
- `SunCalculator` ≈ KosherJava `NOAACalculator`

The key difference is that KosherJava operates on Java `Calendar`/`Date` objects while our model stores everything as **seconds since local midnight** (`localSeconds`), which is the natural unit for Monkey C's `Time.now().value()` combined with UTC offset arithmetic.
