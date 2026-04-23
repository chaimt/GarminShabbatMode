# Implementation Plan: Manual Location Configuration

**Branch**: `004-location-config` | **Date**: 2026-04-22 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/004-location-config/spec.md`

## Summary

Extend the ShabbatMode Garmin watch app with the ability for users to manually configure latitude and longitude coordinates for astronomical calculations, bypassing GPS. The feature adds a `locationSource` field (`"gps"` | `"manual"`) and manual coordinate fields to the existing configuration, extends `LocationService` to respect the source selection, adds a Location section to the existing `TimeSettingsView`, and adds a compact location indicator to `TimeDisplayView`.

## Technical Context

**Language/Version**: Monkey C (Connect IQ SDK 4.0+)  
**Primary Dependencies**: Toybox.WatchUi (NumberPicker / Menu2), Toybox.Application.Storage, existing `ConfigService`, `LocationService`, `TimeConfiguration`, `LocationValidator`  
**Storage**: `Application.Storage` — three new keys: `"locationSource"`, `"manualLatitude"`, `"manualLongitude"`  
**Testing**: Connect IQ Simulator (functional); verify astronomical outputs against known coordinates  
**Target Platform**: Same as feature 003 (Forerunner 965, Venu, fenix, epix — Connect IQ 3.0+)  
**Project Type**: Watch app (Monkey C)  
**Performance Goals**: Location source check adds zero latency to calculation path (simple field read); settings save within 100ms  
**Constraints**: No text-input widget in Monkey C — latitude/longitude entry must use WatchUi number picker or degree/minute selector; values stored as Float (4 decimal places sufficient for ±11m accuracy)  
**Scale/Scope**: Extends ~4 existing files; adds ~3 new files

## Constitution Check

| Principle | Requirement | Compliance |
|-----------|------------|------------|
| I — Shabbat Compliance First | Every decision must prioritize Shabbat observance | ✅ Manual coordinates can be set outside Shabbat; location source setting does not require interaction during Shabbat |
| II — Always-On Display | Screen must never sleep or dim | ✅ No changes to display timer or power management |
| III — Minimal Sensor Footprint | Disable sensors during Shabbat where possible | ✅ Manual mode eliminates GPS polling entirely, reducing sensor usage further |
| IV — Zero Interaction During Shabbat | No user prompts or interaction needed after activation | ✅ Manual coordinates are set in advance; no prompts during Shabbat |
| V — Simplicity and Reliability | Minimal code paths, no network calls during Shabbat | ✅ Manual path is a simple field lookup; no network; fewer moving parts than GPS path |

**Gate result**: ✅ PASS

## Project Structure

### Documentation (this feature)

```text
specs/004-location-config/
├── plan.md              # This file
├── spec.md              # Feature specification
└── tasks.md             # Implementation tasks (to be generated)
```

### Source Code Changes (as implemented)

No new files were created. All changes are extensions to existing files.

```text
src/
├── models/
│   ├── TimeConfiguration.mc      # EXTENDED: getLocationSource(), setLocationSource()
│   └── Configuration.mc          # EXTENDED: getLocationSource(), setLocationSource()
├── services/
│   ├── ConfigService.mc           # EXTENDED: getLocationSource(), setLocationSource()
│   └── LocationService.mc         # EXTENDED: source branching, GPS suppression,
│                                  #   _loadSystemLastKnown(), _loadStorageSettings(),
│                                  #   _isManualMode(), onSourceChanged()
├── lib/
│   └── validators/
│       └── LocationValidator.mc   # EXTENDED: hasValidManualCoords()
└── ui/
    ├── TimeDisplayView.mc          # EXTENDED: Row 5 manual/GPS indicators
    └── TimeSettingsView.mc         # EXTENDED: ITEM_LOC_SOURCE, ITEM_LOC_LAT,
                                   #   ITEM_LOC_LON, ITEM_CAPTURE_GPS, _persistLocation(),
                                   #   onGpsFix() callback

resources/
└── strings/
    └── shabbat_strings.xml         # EXTENDED: location source, capture, indicator strings
```

> **Note**: `LocationConfiguration.mc`, `LocationSettingsComponent.mc`, and layout XML changes
> were planned but not needed — extending existing files proved cleaner and sufficient.

## Triage Framework: [SYNC] vs [ASYNC] Classification

| Task Category | Estimated [SYNC] Tasks | Estimated [ASYNC] Tasks | Rationale |
|---------------|----------------------|----------------------|-----------|
| Model extension | 1 | 1 | Adding fields is boilerplate [ASYNC]; storage key decisions [SYNC] |
| LocationService logic | 2 | 0 | Source-selection branching is risk-critical; wrong branch = wrong calculations |
| Validation extension | 0 | 1 | Range check is formulaic |
| Settings UI | 2 | 1 | WatchUi picker wiring is tricky; layout XML is boilerplate |
| Main view indicator | 1 | 0 | Conditional display logic touches existing rendering |
| Resources/Strings | 0 | 2 | Mechanical XML additions |

## Implementation Notes

- **Coordinate input**: Monkey C's `WatchUi.NumberPicker` (CIQ 3.0+) or a custom `Menu2` approach should be used. Latitude entry: integer degrees (−90 to 90) and decimal portion (0–9999) as two separate pickers. Longitude: same pattern (−180 to 180). Alternatively, a simplified integer-only entry (whole degrees) could be used as a first version if picker complexity is prohibitive — spec does not mandate sub-degree precision beyond 4 decimal places.
- **Storage keys**: Add `"locationSource"` (String), `"manualLatitude"` (Float), `"manualLongitude"` (Float) to `StorageManager`/`ConfigService`.
- **LocationService change**: In `getLocation()`, check `config.locationSource`. If `"manual"` and valid manual coords exist, return a `Location` object built from those. If `"manual"` but no coords, return `null` (callers already handle null). If `"gps"`, existing path unchanged.
- **GPS suppression**: When source = `"manual"`, `LocationService.startUpdates()` should be a no-op (or immediately return the manual location). `BatteryConservationService` GPS interval logic is unchanged — it governs the update interval when GPS is on; manual mode prevents GPS from starting at all.
