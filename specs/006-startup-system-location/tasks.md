---
description: "Task list for startup system location acquisition feature"
---

# Tasks: Startup System Location Acquisition

**Input**: Design documents from `/specs/006-startup-system-location/`  
**Prerequisites**: plan.md ✅, spec.md ✅, context.md ✅  
**Feature Branch**: `006-startup-system-location`  
**Generated**: 2026-04-23

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [SYNC/ASYNC] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[SYNC]**: Requires human review (complex logic, architectural decisions)
- **[ASYNC]**: Can be delegated (well-defined, clear specs)
- **[Story]**: Maps to user story (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify all prerequisites from feature 004 are present before making changes.

- [ ] T001 [ASYNC] Verify that `LocationService` has `_isGpsTracking` field, `startGpsTracking()`, `stopGpsTracking()`, and `isGpsTracking()` in `src/services/LocationService.mc`; verify `AstronomicalService.isGpsTracking()` delegates to it in `src/services/AstronomicalService.mc`; verify `CapturingGpsLabel` string exists in `resources/strings/shabbat_strings.xml` — no code changes, just a read-and-confirm step

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Ensure the GPS tracking flag is reset correctly after a fix arrives before wiring the UI.

- [ ] T002 [SYNC] In `AstronomicalService._onGpsLocationUpdate()` in `src/services/AstronomicalService.mc` — after the `_locationService.setLocation(lat, lon)` call and `new LocationCache().save(lat, lon)`, add `_locationService.stopGpsTracking()` to clear the `_isGpsTracking` flag; this ensures that the very next `onUpdate()` call after the GPS fix will see `isGpsTracking() == false` and render the normal countdown rather than "Acquiring…"; place the call before `WatchUi.requestUpdate()` so the flag is already cleared when the queued redraw fires

**Checkpoint**: Flag lifecycle is correct — `_isGpsTracking` transitions `false → true` in `startGpsTracking()` and `true → false` inside `_onGpsLocationUpdate()`.

---

## Phase 3: User Story 1 — Show "Acquiring…" While GPS Is Active

**Goal**: When no location is available and GPS is in flight, the status line shows "Acquiring GPS…" instead of "Set location for Shabbat times".

**Independent Test**: Clear app location cache in simulator. Launch app in GPS mode. Observe status line shows "Acquiring GPS…" immediately. Simulate GPS fix delivery — status line must switch to the Shabbat countdown within one update cycle.

### Implementation for User Story 1

- [ ] T003 [SYNC] [US1] In `updateCountdownDisplay()` in `src/ui/TimeDisplayView.mc` — locate the block that sets `statusText` to `Rez.Strings.LocationNeeded` when `!_shabbatService.hasLocation()`; replace it with the two-branch check: if `_astronomicalService != null && _astronomicalService.isGpsTracking()` → load `Rez.Strings.CapturingGpsLabel`; else → load `Rez.Strings.LocationNeeded`; keep all surrounding code (color assignment, `_statusComponent.setText(statusText)`) unchanged

**Checkpoint**: US1 complete — "Acquiring GPS…" is shown when GPS is in flight with no location; "Set location for Shabbat times" shown when GPS is idle and no location is configured.

---

## Phase 4: User Story 2 — Correct Startup Location Priority

**Goal**: Confirm the `_loadSystemLastKnown()` → cache → active GPS priority is functioning end-to-end, and that the very first `onUpdate()` frame shows useful content when the OS has a cached GPS position.

**Independent Test**: On a device (or simulator with mocked position) where `Position.getInfo()` returns a valid position: launch with cleared app cache → first frame shows Shabbat countdown times (no "Location needed" flash). Confirm in logs that `_source = "gps_system"` is set by `_loadSystemLastKnown()`.

### Implementation for User Story 2

- [ ] T004 [ASYNC] [US2] Add a startup log entry in `LocationService.initialize()` in `src/services/LocationService.mc` immediately after `_loadSystemLastKnown()` returns — log the value of `_hasLocation` and `_source` so that the startup sequence is visible in simulator logs; no logic change, only a `_logger.info(...)` call for observability
- [ ] T005 [ASYNC] [US2] In `TimeDisplayView.initialize()` in `src/ui/TimeDisplayView.mc` — add a `_logger.info(...)` call after `_astronomicalService = new AstronomicalService()` that logs `_astronomicalService.hasLocation()` to confirm whether the system-seeded location was available before `onShow()` fires; no logic change

**Checkpoint**: US2 complete — startup logs confirm `_loadSystemLastKnown()` runs before `onShow()`, and whether a location was immediately available.

---

## Phase 5: User Story 3 — GPS Tracking Status Accessible to Views

**Goal**: `TimeDisplayView` correctly uses `AstronomicalService.isGpsTracking()` (which already exists) to gate the "Acquiring…" indicator — no new public API needed.

**Independent Test**: Set a breakpoint (or add logs) in `updateCountdownDisplay()`. Confirm `isGpsTracking()` returns `true` between `onShow()` and the GPS callback, then `false` afterwards.

### Implementation for User Story 3

- [ ] T006 [P] [ASYNC] [US3] Add observability log to `AstronomicalService.startGpsTracking()` in `src/services/AstronomicalService.mc` — after the `_locationService.startGpsTracking(...)` call, log `"AstronomicalService: GPS tracking started, isGpsTracking=" + isGpsTracking()`; ensures the flag state is confirmed in simulator logs
- [ ] T007 [P] [ASYNC] [US3] Add observability log to `AstronomicalService._onGpsLocationUpdate()` in `src/services/AstronomicalService.mc` — after `_locationService.stopGpsTracking()`, log `"AstronomicalService: GPS fix received, tracking cleared, isGpsTracking=" + isGpsTracking()`; confirms the flag is `false` before `WatchUi.requestUpdate()` fires

**Checkpoint**: US3 complete — `isGpsTracking()` is verifiably correct throughout the acquisition lifecycle; `TimeDisplayView` uses it to drive the status indicator.

---

## Phase 6: Polish & Validation

- [ ] T008 [ASYNC] Build the project with `task build` (or equivalent Taskfile target) from repo root — resolve any compile errors from T002, T003, T004, T005, T006, T007; confirm zero warnings on changed files
- [ ] T009 [ASYNC] End-to-end simulator test — scenario A: launch with no location → status shows "Acquiring GPS…" → simulate GPS event → status shows countdown; scenario B: launch with OS GPS cache populated → first frame shows countdown (no "acquiring" flash); confirm both scenarios pass in logs

---

## Dependencies

```
T001 → T002 → T003                   (verify prerequisites → fix flag lifecycle → wire UI)
T002 → T004, T005                    (flag correct before adding observability)
T003, T004, T005 → T006, T007        (all core changes before observability logs)
T006, T007 → T008 → T009             (build and test last)
```

## Parallel Execution Opportunities

- T004 and T005 can run in parallel (different files: `LocationService.mc` vs `TimeDisplayView.mc`)
- T006 and T007 can run in parallel (both in `AstronomicalService.mc` but different methods — sequential for safety)

## Implementation Strategy (MVP)

- **MVP = T001 + T002 + T003** (3 tasks): Core flag fix + UI indicator — directly solves the user-facing problem
- **US2 observability** (T004, T005): Low-risk log additions for verification
- **US3 observability** (T006, T007): Log additions to confirm flag lifecycle
- **Polish** (T008, T009): Build + end-to-end test
