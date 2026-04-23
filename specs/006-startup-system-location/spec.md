# Feature Specification: Startup System Location Acquisition

**Feature Branch**: `006-startup-system-location`  
**Created**: 2026-04-23  
**Status**: Draft  
**Input**: User description: "when starting app it should get location from the garmin system"

## Background

When the app starts without a cached location, it calls `startGpsTracking()` in `onShow()` — but the UI immediately shows the static "Set location for Shabbat times" message. The user has no feedback that GPS acquisition is already in progress. The string `CapturingGpsLabel = "Acquiring…"` already exists in `shabbat_strings.xml` but is never used. This feature wires up the full startup acquisition flow: system last-known → active GPS → visible status.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Show "Acquiring…" While GPS Is Active (Priority: P1)

As a first-time user (or a user with no cached location), I want to see "Acquiring GPS…" on the main screen when the app is actively requesting a GPS fix so I know it is working and I do not need to take any action.

**Why this priority**: Core UX requirement — without this the user sees "Set location for Shabbat times" and may think the app is broken or waiting for them to do something.

**Independent Test**: Launch the app with no location cache and GPS source selected. Observe the status line: it must show "Acquiring GPS…" from the moment `onShow()` fires until a GPS fix is received. After the fix: the status line must switch to the normal countdown or location indicator within one `requestUpdate()` cycle.

**Acceptance Scenarios**:

1. **Given** the app is in countdown mode with no cached location, **When** `onShow()` fires, **Then** the status line shows the `CapturingGpsLabel` string ("Acquiring…") immediately
2. **Given** the "Acquiring…" indicator is visible, **When** a GPS fix is received by `AstronomicalService._onGpsLocationUpdate()`, **Then** `WatchUi.requestUpdate()` is called, and the next `onUpdate()` renders the Shabbat countdown with the acquired location
3. **Given** location source is set to "Manual", **When** `onShow()` fires, **Then** "Acquiring…" is NOT shown (GPS tracking is suppressed for manual mode)
4. **Given** a cached location is already available from a previous session, **When** `onShow()` fires and GPS tracking starts, **Then** the cached location is used immediately for display while the GPS fix updates silently in the background

---

### User Story 2 - Correct Startup Location Priority (Priority: P1)

As a returning user, I want the app to immediately show Shabbat times using the best available location on startup (in priority order: system last-known GPS → location cache → active GPS acquisition) so the display is useful from the first frame.

**Why this priority**: Directly implements "when starting app it should get location from the garmin system" — the system's cached GPS position (`Position.getInfo()`) must be checked BEFORE showing "Location needed" or "Acquiring…".

**Independent Test**: On a device that has recently been used for activity tracking (GPS fix is in the OS cache), launch ShabbatMode with the app's own location cache cleared. Verify that Shabbat times appear on the first frame (no "Location needed" flash) because `_loadSystemLastKnown()` populated the location during `initialize()`.

**Acceptance Scenarios**:

1. **Given** the OS has a recent GPS fix (e.g., from a recent run), **When** the app starts, **Then** `Position.getInfo()` returns a valid position and `LocationService._loadSystemLastKnown()` seeds the location immediately — no "Location needed" is shown
2. **Given** the OS GPS cache is empty but the app has its own location cache, **When** the app starts, **Then** the cached location is used for immediate display
3. **Given** neither OS nor app cache has a location, **When** `onShow()` fires, **Then** `startGpsTracking()` is called and "Acquiring…" is shown until a fix arrives
4. **Given** the app already has a location (from any source), **When** `startGpsTracking()` fires in `onShow()`, **Then** the existing location is shown immediately and the GPS fix silently updates it when it arrives (no visible "acquiring" flash)

---

### User Story 3 - GPS Tracking Status Accessible to Views (Priority: P2)

As a developer, I want `AstronomicalService` to expose whether GPS tracking is currently active so that any view can check `isGpsTracking()` and render an appropriate indicator without tight coupling to `LocationService`.

**Why this priority**: Clean architecture — `AstronomicalService.isGpsTracking()` already exists but `TimeDisplayView` does not consult it when choosing the status text. This user story wires that up.

**Independent Test**: Call `_astronomicalService.isGpsTracking()` from `TimeDisplayView.updateCountdownDisplay()` and confirm it returns `true` between `onShow()` and the GPS callback, and `false` afterwards.

**Acceptance Scenarios**:

1. **Given** `TimeDisplayView.onShow()` calls `startGpsTracking()`, **When** `updateCountdownDisplay()` builds the status text, **Then** it calls `_astronomicalService.isGpsTracking()` to distinguish "Acquiring…" from "Set location for Shabbat times"
2. **Given** GPS tracking is active AND a location is already available (background refresh), **When** `updateCountdownDisplay()` runs, **Then** it shows the normal countdown (not "Acquiring…") because location is already present
3. **Given** GPS tracking completes and `_onGpsLocationUpdate()` fires, **When** `WatchUi.requestUpdate()` is called, **Then** `isGpsTracking()` returns `false` and the next `onUpdate()` shows normal content
