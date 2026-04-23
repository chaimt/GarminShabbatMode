# Implementation Plan: Always-On Screen While App Is Running

**Branch**: `005-screen-always-on` | **Date**: 2026-04-23 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/005-screen-always-on/spec.md`

## Summary

Add a dedicated `DisplayService` that runs a short-interval keep-alive timer (≤5 seconds) to prevent the Garmin watch display from sleeping while the ShabbatMode widget is in the foreground. The keep-alive is separate from the display refresh timer (`BatteryConservationService`) so conservation mode's 30-second refresh rate is preserved while the screen stays lit. `MainView` gains a `_displayService` field and starts/stops it in `onShow()`/`onHide()`. `onUpdate()` gains a lightweight path for keep-alive-only ticks that redraws cached content without recomputing astronomical data.

## Technical Context

**Language/Version**: Monkey C (Connect IQ SDK 4.0+)  
**Primary Dependencies**: `Toybox.WatchUi`, `Toybox.Timer`, existing `MainView`, `BatteryConservationService`  
**Storage**: None — no persistent state required  
**Testing**: Connect IQ Simulator (observe display in foreground for 60+ seconds in both normal and conservation modes)  
**Target Platform**: Forerunner 965, Venu 2, fenix 7 — Connect IQ 3.0+  
**Project Type**: Watch widget (Monkey C)  
**Performance Goals**: Keep-alive tick must not trigger astronomical recalculation; total keep-alive overhead < 1ms per tick  
**Constraints**:
- `WatchUi.requestUpdate()` is the only CIQ mechanism available in widget apps to prevent display sleep
- Keep-alive interval must be shorter than the device's display-off timeout (typically 10–30s depending on model and user settings); **5 seconds** is chosen as a safe universal value
- The keep-alive fires even during conservation mode (every 5s) — this is unavoidable but the actual `onUpdate()` work is lightweight (just redraw cached layout)
- No new storage keys needed

**Scale/Scope**: Adds 1 new file (`DisplayService.mc`); modifies 1 file (`MainView.mc`)

## Constitution Check

| Principle | Requirement | Compliance |
|-----------|------------|------------|
| I — Shabbat Compliance First | Every decision must prioritize Shabbat observance | ✅ Keep-alive fires passively; no user interaction required; screen staying on is the desired behavior during Shabbat |
| II — Always-On Display | Screen must never sleep or dim | ✅ This feature directly implements Principle II |
| III — Minimal Sensor Footprint | Disable sensors during Shabbat | ✅ No new sensors activated; keep-alive only calls `requestUpdate()` |
| IV — Zero Interaction During Shabbat | No user prompts after activation | ✅ Keep-alive is fully automatic; user does nothing |
| V — Simplicity and Reliability | Minimal code paths | ✅ `DisplayService` is ~40 lines; single responsibility; no new state |

**Gate result**: ✅ PASS

## Project Structure

### Documentation (this feature)

```text
specs/005-screen-always-on/
├── plan.md              # This file
├── spec.md              # Feature specification
└── tasks.md             # Implementation tasks
```

### Source files changed

```text
src/services/
└── DisplayService.mc    # NEW — keeps screen awake via 5s keep-alive timer

src/ui/
└── MainView.mc          # MODIFIED — add _displayService field, start/stop in onShow/onHide,
                         #   add _isKeepAliveTick flag and lightweight redraw path in onUpdate
```

## Architecture

### DisplayService

```text
DisplayService
  KEEP_ALIVE_INTERVAL_MS = 5000   // 5 seconds
  _timer: Timer.Timer
  _isRunning: Boolean
  _onKeepAlive: Method (callback to MainView)

  initialize(callback)  → store callback reference
  start()               → create + start _timer at KEEP_ALIVE_INTERVAL_MS
  stop()                → stop _timer
  isRunning()           → Boolean
  _onTick()             → call _onKeepAlive
```

### MainView changes

```text
MainView
  + _displayService: DisplayService
  + _isKeepAliveTick: Boolean
  + _cachedDisplayState: Lang.Symbol  // :countdown | :shabbat | :conservation

  onShow()    → start _displayService (in addition to _updateTimer)
  onHide()    → stop _displayService
  onKeepAlive() → set _isKeepAliveTick = true; call WatchUi.requestUpdate()
  onUpdate()  → if _isKeepAliveTick: redraw with cached state, reset flag; else: full update as before
```

### Timer interaction diagram

```
Normal mode (non-Shabbat):
  _updateTimer    ----1s----1s----1s----1s----1s----→  full redraw + recalc
  _displayService ----5s---------5s---------5s----→  keep-alive (no-op: screen already awake)

Conservation mode (Shabbat):
  _updateTimer    ----30s-----------------------------30s----→  full redraw + recalc
  _displayService ----5s--5s--5s--5s--5s--5s--5s--5s--5s----→  keep-alive (lightweight redraw)
```

## Implementation Notes

- `_isKeepAliveTick` is reset to `false` at the top of `onUpdate()` after use
- During conservation mode keep-alive ticks, `onUpdate()` simply re-invokes the appropriate `update*Display()` helper with cached data — no `_shabbatService` or astronomical calls
- `_cachedDisplayState` tracks which display helper to call on keep-alive: `:countdown`, `:shabbat`, or `:conservation`
- On a real Shabbat content tick (30s), `_isKeepAliveTick` is `false` and the full update path runs as before, refreshing `_cachedDisplayState`
