# Implementation Plan: Startup System Location Acquisition

**Branch**: `006-startup-system-location` | **Date**: 2026-04-23 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/006-startup-system-location/spec.md`

## Summary

Wire up the startup GPS acquisition flow that already exists in code (T022 / feature 004) but is invisible to the user. Two targeted changes: (1) `TimeDisplayView.updateCountdownDisplay()` checks `_astronomicalService.isGpsTracking()` to show "Acquiring GPS…" instead of "Set location for Shabbat times" when GPS is in flight; (2) `AstronomicalService._onGpsLocationUpdate()` resets `_isGpsTracking` to `false` after the fix is delivered so the indicator clears automatically.

No new files. Changes are confined to `src/ui/TimeDisplayView.mc` and `src/services/AstronomicalService.mc`.

## Technical Context

**Language/Version**: Monkey C (Connect IQ SDK 4.0+)  
**Primary Dependencies**: `AstronomicalService.isGpsTracking()` (already exists), `Rez.Strings.CapturingGpsLabel` (already exists in `shabbat_strings.xml`), `LocationService._isGpsTracking` flag (already maintained by `startGpsTracking()` / `stopGpsTracking()`)  
**Storage**: No new storage keys  
**Testing**: Connect IQ Simulator — clear location cache, launch, observe status line transitions  
**Target Platform**: Forerunner 965, Venu 2, fenix 7 — Connect IQ 3.0+  
**Project Type**: Watch widget (Monkey C)  
**Performance Goals**: Zero additional computation — one extra boolean check per `onUpdate()` tick  
**Constraints**:
- `Position.LOCATION_ONE_SHOT` fires the callback exactly once then the radio turns off; `_isGpsTracking` must be set to `false` in the callback handler
- `AstronomicalService.isGpsTracking()` delegates to `_locationService.isGpsTracking()` — this flag is already correct for the "tracking in progress" window
- No change to `BatteryConservationService` or the Shabbat display path — "Acquiring…" only appears in countdown mode (not during Shabbat)
- During Shabbat GPS is suppressed (`startGpsTracking()` is a no-op when manual or during Shabbat conservation); "Acquiring…" cannot appear during Shabbat

**Scale/Scope**: Modifies 2 existing files; adds 0 new files; changes ~15 lines total

## Constitution Check

| Principle | Requirement | Compliance |
|-----------|------------|------------|
| I — Shabbat Compliance First | No new sensor activation or interaction during Shabbat | ✅ "Acquiring…" only shown in countdown mode; GPS suppression during Shabbat is unchanged |
| II — Always-On Display | Screen remains on | ✅ No changes to timer or display management |
| III — Minimal Sensor Footprint | Suppress sensors during Shabbat | ✅ GPS tracking is already suppressed during Shabbat; this feature adds no new GPS calls |
| IV — Zero Interaction | No prompts during Shabbat | ✅ Indicator is informational only; no input required; not shown during Shabbat |
| V — Simplicity | Minimal code paths | ✅ One boolean check and one string substitution — minimal change |

**Gate result**: ✅ PASS

## Project Structure

### Documentation (this feature)

```text
specs/006-startup-system-location/
├── plan.md              # This file
├── spec.md              # Feature specification
├── context.md           # Feature context
└── tasks.md             # Implementation tasks
```

### Source files changed

```text
src/ui/TimeDisplayView.mc
  updateCountdownDisplay()  → check isGpsTracking() to show "Acquiring…" vs "Set location for Shabbat times"

src/services/AstronomicalService.mc
  _onGpsLocationUpdate()    → set _isGpsTracking = false via _locationService.stopGpsTracking() after successful fix
                              (LocationService.stopGpsTracking() already exists; ensure it is called here)
```

## Architecture

### Status Text Decision Tree in `updateCountdownDisplay()`

```
hasLocation()?
  YES → show countdown (normal path — unchanged)
  NO  → isGpsTracking()?
          YES → show CapturingGpsLabel ("Acquiring…")
          NO  → show LocationNeeded ("Set location for Shabbat times")
```

### GPS Flag Lifecycle

```
onShow()
  → startGpsTracking()       → _isGpsTracking = true
      [GPS radio fires once]
  → _onGpsLocationUpdate()   → setLocation(), cache, recalc
                             → stopGpsTracking()   → _isGpsTracking = false
                             → WatchUi.requestUpdate()
      [next onUpdate() call]
  → updateCountdownDisplay() → isGpsTracking() = false → show countdown
```

### `_loadSystemLastKnown()` path (zero-radio, instant)

```
initialize()
  → _loadFromCache()
  → _loadSystemLastKnown()   → Position.getInfo() [no radio cost]
      → if valid: _hasLocation = true, _source = "gps_system"
        → onShow() runs → hasLocation() = true → countdown shown immediately
        → startGpsTracking() fires for fresh update (silent background refresh)
```

## Detailed Change Description

### `src/services/AstronomicalService.mc` — `_onGpsLocationUpdate()`

After calling `_locationService.setLocation(lat, lon)` and `new LocationCache().save(lat, lon)`:
```
_locationService.stopGpsTracking();   // clear _isGpsTracking flag
```
`stopGpsTracking()` already exists and only clears the boolean — it does not issue any hardware stop call (the ONE_SHOT radio already auto-stopped).

### `src/ui/TimeDisplayView.mc` — `updateCountdownDisplay()`

Replace the existing status-text assignment block with:
```
if (_shabbatService != null && !_shabbatService.hasLocation()) {
    if (_astronomicalService != null && _astronomicalService.isGpsTracking()) {
        statusText = WatchUi.loadResource(Rez.Strings.CapturingGpsLabel) as Lang.String;
    } else {
        statusText = WatchUi.loadResource(Rez.Strings.LocationNeeded) as Lang.String;
    }
}
```
