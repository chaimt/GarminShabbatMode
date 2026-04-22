# Implementation Plan: Shabbat Time Display

**Branch**: `003-shabbat-time-display` | **Date**: 2026-04-22 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/003-shabbat-time-display/spec.md`

## Summary

Implement a comprehensive time-display system for the ShabbatMode Garmin watch app that shows current time, astronomical sunrise/sunset, candle lighting time, and end-of-Shabbat time. All astronomical calculations are implemented in Monkey C using the NOAA Simplified Solar Algorithm — the same algorithm used by the KosherJava Zmanim reference library (https://kosherjava.com/zmanim-project/) — ported to the Garmin Connect IQ runtime environment. The feature also introduces Shabbat battery conservation mode: an app-level activity reduction (not system DND) that cuts screen refresh by 97% and GPS polling by 6× during the Shabbat window.

## Technical Context

**Language/Version**: Monkey C (Connect IQ SDK 4.0+)  
**Primary Dependencies**: Toybox.Position (GPS), Toybox.Time, Toybox.Time.Gregorian, Toybox.Math, Toybox.WatchUi, Toybox.Application, Toybox.Timer  
**Storage**: `Application.Storage` (persistent location cache); in-memory `CalculationCache` for daily astronomical data  
**Testing**: Connect IQ Simulator (functional / regression); on-device testing for sensor + battery behavior  
**Target Platform**: Garmin watches with Connect IQ 3.0+ and always-on display capability (Forerunner 965, Venu series, fenix series, epix series)  
**Project Type**: Watch app (Monkey C — single-file `.iq` distributed via Connect IQ Store)  
**Performance Goals**: All astronomical calculations complete within 500ms (SC-004); display updates within 1s of clock tick (SC-001)  
**Constraints**: No JVM / no external libraries; limited IEEE 754 float precision (32-bit on most CIQ devices); offline operation required after first GPS fix; 25+ hour battery endurance target  
**Scale/Scope**: Single-user, single-device app; ~30 Monkey C source files across `src/`, `resources/`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Requirement | Compliance |
|-----------|------------|------------|
| I — Shabbat Compliance First | Every decision must prioritize Shabbat observance | ✅ Candle-lighting and end-of-Shabbat calculations are halachically correct; battery conservation mode reduces melacha activity |
| II — Always-On Display | Screen must never sleep or dim | ✅ `MainView` holds a `Toybox.Timer` that prevents sleep; display stays on throughout Shabbat window |
| III — Minimal Sensor Footprint | Disable sensors during Shabbat where possible | ✅ `BatteryConservationService` extends GPS poll interval to 30 min during Shabbat; pre-calculated times cached so GPS is unnecessary once acquired |
| IV — Zero Interaction During Shabbat | No user prompts or interaction needed after activation | ✅ All time calculations are automatic; no button presses required during Shabbat window |
| V — Simplicity and Reliability | Minimal code paths, no network calls during Shabbat | ✅ NOAA algorithm is pure math (no network); location cached for 24h; graceful polar-region fallback |

**Gate result**: ✅ PASS — All constitutional principles satisfied. No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/003-shabbat-time-display/
├── plan.md              # This file
├── research.md          # Phase 0: KosherJava algorithm mapping & decisions
├── data-model.md        # Phase 1: Entity definitions and relationships
├── quickstart.md        # Phase 1: Developer setup guide
└── tasks.md             # Phase 2: Implementation tasks (all complete)
```

### Source Code (repository root)

```text
src/
├── cache/
│   ├── CalculationCache.mc       # Daily astronomical data cache (dayId-keyed)
│   └── LocationCache.mc          # Persistent GPS coordinate storage
├── lib/
│   ├── calculations/
│   │   └── DateMath.mc           # J2000.0 day numbers, epoch conversions
│   ├── formatters/
│   │   └── TimeFormatter.mc      # HH:MM / 12h/24h formatting
│   ├── logging/
│   │   └── Logger.mc             # Debug logging wrapper
│   ├── storage/
│   │   └── StorageManager.mc     # Application.Storage abstraction
│   ├── validation/
│   │   └── Validator.mc          # Generic validation utilities
│   └── validators/
│       └── LocationValidator.mc  # GPS coordinate + polar-region check
├── models/
│   ├── Application.mc            # App-level state model
│   ├── AstronomicalData.mc       # Sunrise / sunset seconds-since-midnight
│   ├── Configuration.mc          # App-wide config
│   ├── Location.mc               # lat/lon/elevation
│   ├── ShabbatTimes.mc           # Candle lighting + end-of-Shabbat times
│   ├── TimeConfiguration.mc      # Configurable offsets (candle, tzais)
│   └── TimeInfo.mc               # Current local time (HH:MM:SS)
├── services/
│   ├── AstronomicalService.mc    # Sunrise/sunset computation + daily cache
│   ├── BatteryConservationService.mc  # Shabbat activity reduction manager
│   ├── ConfigService.mc          # Reads/writes TimeConfiguration
│   ├── LocationService.mc        # GPS acquisition + caching
│   ├── ShabbatTimeService.mc     # Candle lighting + end-of-Shabbat times
│   ├── ShabbatWindowService.mc   # Detects Shabbat period (Fri→Sat)
│   ├── SunCalculator.mc          # NOAA solar algorithm (core math)
│   ├── TimeService.mc            # Real-time clock ticker (1s or 30s)
│   └── TimezoneService.mc        # UTC offset derivation
└── ui/
    ├── components/
    │   ├── BaseComponent.mc
    │   ├── ClockComponent.mc     # Current time display
    │   ├── ShabbatTimesComponent.mc  # Candle + havdalah times
    │   └── SunTimesComponent.mc  # Sunrise / sunset times
    ├── MainView.mc               # Root view; dispatches to conservation or full display
    ├── TimeDisplayView.mc        # Full-detail time display (non-Shabbat)
    └── TimeSettingsView.mc       # User preferences (candle offset, tzais offset)

resources/
├── layouts/
│   ├── time_display_layout.xml
│   └── time_settings_layout.xml
└── strings/
    ├── shabbat_strings.xml       # Shabbat-domain + settings strings
    ├── strings.xml               # General app strings
    └── time_strings.xml          # Time-display labels and status messages
```

**Structure Decision**: Single-project layout matching the existing `src/` tree established in feature 001-base-application. No monorepo split needed for a single-device watch app.

## Triage Framework: [SYNC] vs [ASYNC] Classification

**Execution Strategy**: Hybrid model — complex halachic calculation logic and UI wiring are [SYNC]; boilerplate models, resource files, and well-defined formatters are [ASYNC].

### Preliminary Task Classification

| Task Category | Estimated [SYNC] Tasks | Estimated [ASYNC] Tasks | Rationale |
|---------------|----------------------|----------------------|-----------|
| Astronomical Calculations | 3 | 2 | NOAA algorithm port is risk-critical; caching and utility helpers are well-defined |
| Shabbat Time Logic | 4 | 1 | Halachic correctness requires human judgment; model scaffold is boilerplate |
| UI Components | 3 | 2 | Conservation-mode rendering and MainView wiring need architectural care |
| Location Services | 2 | 2 | GPS acquisition patterns and fallback are tricky; validators are formulaic |
| Resources / Strings | 0 | 5 | XML resource files are mechanical; no business logic |
| Battery Conservation | 2 | 1 | Timer interval tuning and state machine are risk-critical |

### Triage Decision Criteria Applied

**High-Risk [SYNC] Classifications:**
- `SunCalculator.mc` — NOAA algorithm port; floating-point precision at Garmin SDK level; accuracy requirement ±2 min
- `AstronomicalService.mc` — day-boundary cache invalidation and UTC→local-time conversion
- `ShabbatWindowService.mc` — Shabbat period detection (Friday nightfall → Saturday nightfall); halachic correctness
- `ShabbatTimeService.mc` — candle lighting and tzais offsets; configurable defaults with halachic justification
- `BatteryConservationService.mc` — Shabbat transition state machine; SC-005/SC-006 compliance
- `MainView.mc` (conservation mode rendering) — timer restart after Shabbat transitions
- String resource extraction (T064–T070) — touches all UI files; regression risk

**Agent-Delegated [ASYNC] Classifications:**
- Model scaffolds (`AstronomicalData.mc`, `ShabbatTimes.mc`, `Location.mc`, `TimeInfo.mc`)
- Utility classes (`DateMath.mc`, `TimeFormatter.mc`, `LocationValidator.mc`)
- Resource XML files (layouts, strings)
- `CalculationCache.mc` — straightforward key-value cache
- `LocationCache.mc` — thin `Application.Storage` wrapper

### Triage Audit Trail

| Task | Classification | Primary Criteria | Risk Level | Rationale |
|------|----------------|------------------|------------|-----------|
| SunCalculator NOAA port | [SYNC] | Complex algorithm, accuracy-critical | High | ±2 min accuracy is a hard requirement; algorithm has known edge cases at extreme latitudes |
| AstronomicalService caching | [SYNC] | Day-boundary logic, UTC conversion | Med | Daylight saving transitions and midnight-crossing require careful offset handling |
| ShabbatWindowService | [SYNC] | Halachic logic, state machine | High | Incorrect Shabbat window detection would cause wrong battery mode activation |
| ShabbatTimeService offsets | [SYNC] | Halachic correctness, configurable defaults | High | Default tzais offset (42 min vs 25 min) is a religious decision with practical consequences |
| BatteryConservationService | [SYNC] | State machine, real device testing required | High | Timer-based Shabbat transitions must not silently fail overnight |
| MainView conservation mode | [SYNC] | UI wiring + timer restart on transitions | Med | Incorrect timer restart frequency would violate SC-005 (≥80% refresh reduction) |
| String extraction (T064–T070) | [SYNC] | Multi-file refactor, regression risk | Med | Touches all UI files; hardcoded strings must not remain in any .mc file |
| AstronomicalData model | [ASYNC] | Boilerplate data container | Low | Plain struct with getters; no business logic |
| ShabbatTimes model | [ASYNC] | Simple calculation wrapper | Low | Arithmetic on sunset offsets; predictable |
| TimeFormatter | [ASYNC] | Standard string formatting | Low | HH:MM formatting is straightforward |
| LocationValidator | [ASYNC] | Formulaic polar check (|lat| > 66.5) | Low | Single boolean check |
| Resource XML files | [ASYNC] | No business logic | Low | Mechanical key-value files |
| CalculationCache | [ASYNC] | Simple dictionary | Low | Map with dayId key; no complex invalidation |

## Complexity Tracking

> No constitutional violations requiring justification were identified.

All design decisions are within the constitutional bounds. The degree-based tzais calculation (KosherJava uses solar-angle-based nightfall) was evaluated but **not implemented** in the initial version — see `research.md` § "Tzais Calculation Method". Fixed-minute offsets are used instead, which is the standard approach for most Jewish communities and aligns with Principle V (Simplicity).
