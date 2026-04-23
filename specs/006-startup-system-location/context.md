# Feature Context

**Feature**: Startup System Location Acquisition
**Mission**: Show "Acquiring GPS…" while the app is actively acquiring a location fix on startup, and immediately use the Garmin system's last-known GPS position when available — eliminating the false "Set location for Shabbat times" flash.
**Code Paths**: `src/ui/TimeDisplayView.mc` (updateCountdownDisplay), `src/services/AstronomicalService.mc` (_onGpsLocationUpdate)

## Technical Context

**Language**: Monkey C (Connect IQ SDK 4.0+)  
**Key APIs**: `AstronomicalService.isGpsTracking()`, `LocationService.stopGpsTracking()`, `Rez.Strings.CapturingGpsLabel`, `Position.getInfo()` (via `_loadSystemLastKnown()`)  
**Permissions Required**: `Positioning` (already in manifest)  
**Dependencies**: Feature 004 (location-config) must be merged first — `_loadSystemLastKnown()` and `_isGpsTracking` flag both originate there

## Personas

- First-time user launching ShabbatMode before configuring location — sees "Acquiring GPS…" then times appear automatically
- Returning user whose device has a recent GPS fix (from running, cycling) — sees Shabbat times immediately on the first frame with no "acquiring" phase

## Constraints

- `CapturingGpsLabel` string already exists in `shabbat_strings.xml` — reuse it, do not add a new string
- `isGpsTracking()` must return `false` immediately after the GPS callback fires — ensure `stopGpsTracking()` is called inside `_onGpsLocationUpdate()` on success
- The "Acquiring…" state is only shown in countdown mode (not Shabbat mode or conservation mode) — no change to the Shabbat display paths
- Minimal change surface: only 2 files, ~15 lines total

## Key Technical Challenges

- Ensuring `stopGpsTracking()` is called in `_onGpsLocationUpdate()` so the "Acquiring…" indicator clears as soon as the fix arrives (without an extra timer tick)
- Correctly scoping the "Acquiring…" condition: show only when `!hasLocation()` AND `isGpsTracking()`, not when location is already available from cache/system
