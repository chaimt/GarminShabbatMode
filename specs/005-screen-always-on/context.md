# Feature Context

**Feature**: Always-On Screen While App Is Running
**Mission**: Prevent the Garmin watch display from sleeping while the ShabbatMode widget is in the foreground, implementing Constitution Principle II (Always-On Display)
**Code Paths**: src/services/DisplayService.mc (new), src/ui/MainView.mc (modified)

## Technical Context

**Language**: Monkey C (Connect IQ SDK 4.0+)
**Key APIs**: Toybox.WatchUi.requestUpdate(), Toybox.Timer.Timer
**Permissions Required**: None (no new permissions needed)
**Dependencies**: Feature 003 (shabbat-time-display) — extends MainView; feature 004 (location-config) must also be complete (or branch from it)

## Personas

- Shabbat observer who has activated ShabbatMode and sets the watch on a table — needs the time visible without touching the watch
- User checking time during Shabbat without wrist gesture (arm down, table-mounted watch)

## Constraints

- `WatchUi.requestUpdate()` is the only mechanism available in Connect IQ widget apps to prevent display sleep (no OS-level "wake lock" API)
- Keep-alive interval must be < display-off timeout (typically 10–30s per device/settings); 5s is chosen as the safe universal value
- Keep-alive fires even during Shabbat conservation mode; the `onUpdate()` keep-alive path must be lightweight to not undermine battery conservation
- `_isKeepAliveTick` flag pattern used to distinguish keep-alive ticks from real content ticks in `onUpdate()`
- No new storage keys, no new permissions, no new UI screens required

## Key Technical Challenges

- Distinguishing keep-alive `onUpdate()` calls from real content-refresh calls so that expensive astronomical recalculations are skipped during keep-alive ticks
- Ensuring the keep-alive timer is always stopped in `onHide()` to avoid background battery drain
- Handling the case where `_displayService` initialization fails gracefully (e.g., null reference) without crashing the app
