# Tasks: Manual Location Configuration

**Input**: Design documents from `/specs/004-location-config/`  
**Prerequisites**: plan.md ✅, spec.md ✅, context.md ✅  
**Feature Branch**: `004-location-config`  
**Generated**: 2026-04-22

## Format: `[ID] [P?] [SYNC/ASYNC] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[SYNC]**: Requires human review (complex logic, security-critical, ambiguous)
- **[ASYNC]**: Can be delegated to async agents (well-defined, clear specs)
- **[Story]**: Maps to user story (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add storage key constants needed by all subsequent phases

- [x] T001 [ASYNC] Add storage key constants `LOCATION_SOURCE_KEY`, `MANUAL_LATITUDE_KEY`, `MANUAL_LONGITUDE_KEY` to `src/lib/storage/StorageManager.mc`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extend the core model, config service, and validator so that all user story implementations can read/write and validate the new location configuration fields.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 [SYNC] Extend `src/models/TimeConfiguration.mc` with three new fields: `locationSource` (String, default `"gps"`), `manualLatitude` (Float, default `0.0`), `manualLongitude` (Float, default `0.0`); update constructor and any copy/serialisation helpers
- [x] T003 [P] [ASYNC] Extend `src/services/ConfigService.mc` with `getLocationSource()`, `setLocationSource(source)`, `getManualLatitude()`, `setManualLatitude(lat)`, `getManualLongitude()`, `setManualLongitude(lon)` — each backed by `Application.Storage` via the constants from T001
- [x] T004 [P] [ASYNC] Extend `src/lib/validation/LocationValidator.mc` with `validateManualCoords(lat, lon)` returning `Boolean` (true when lat ∈ [−90, 90] and lon ∈ [−180, 180]) and `hasValidManualCoords(config)` convenience method

**Checkpoint**: Model + ConfigService + Validator ready — user story phases can now begin.

---

## Phase 3: User Story 1 — Manual Location Entry in Settings (Priority: P1) 🎯 MVP

**Goal**: Users can open the settings screen, enter a latitude and longitude, and save them so that astronomical calculations use those coordinates.

**Independent Test**: Open `TimeSettingsView` in the simulator, navigate to the Location section, enter lat=40.6892 lon=-74.0445 (New York), save, close the app and reopen — verify values are persisted and sunrise/sunset times match New York references within ±2 minutes.

### Implementation for User Story 1

- [x] T005 [ASYNC] [US1] Add location-related string keys to `resources/strings/shabbat_strings.xml`: `LocationSourceLabel`, `LocationSourceGps`, `LocationSourceManual`, `LatitudeSettingFormat`, `LongitudeSettingFormat`, `LocationSourceSettingFormat`, `ManualLocNoCoords`, `LocationIndicatorManual`, `LocationIndicatorNoCoords`
- [x] T006 [SYNC] [US1] Integrate location settings directly into `src/ui/TimeSettingsView.mc` (no separate component needed — consistent with existing watch UI pattern): source toggle (GPS/Manual), lat degree incrementer, lon degree incrementer; polar warning appended to lat row
- [x] T007 [ASYNC] [US1] Location settings drawn in code (existing TimeSettingsView pattern); no layout XML changes needed — items rendered inline with dimming for inactive lat/lon rows in GPS mode
- [x] T008 [SYNC] [US1] Extend `src/ui/TimeSettingsView.mc` with `ITEM_LOC_SOURCE`, `ITEM_LOC_LAT`, `ITEM_LOC_LON` items; SELECT cycles source and increments degrees; lat/lon rows dimmed when GPS mode; polar warning shown inline
- [x] T009 [ASYNC] [US1] Quickstart notes added inline in implementation — manual testing: navigate to Settings (SELECT), scroll to Location section, toggle to Manual, increment lat/lon, verify persistence by cycling back to the view

**Checkpoint**: US1 fully functional and independently testable — users can enter and persist manual coordinates.

---

## Phase 4: User Story 2 — Location Source Toggle (Priority: P1)

**Goal**: Users can switch between GPS and Manual location sources; the app immediately respects the selected source for all calculations and GPS hardware events.

**Independent Test**: Set source to "Manual" with valid coords — verify no `Position.enableLocationEvents` calls occur and `LocationService.getLocation()` returns the manual coordinates. Set source back to "GPS" — verify GPS polling resumes within one timer cycle.

### Implementation for User Story 2

- [x] T010 [SYNC] [US2] Implement `refresh()` source branching in `src/services/LocationService.mc`: reads `_isManualSourceConfigured()` from persistent storage; if manual, calls `_tryManual()` directly (no GPS); if GPS, tries GPS then falls back to manual
- [x] T011 [SYNC] [US2] Implement GPS suppression: `startGpsTracking()` is a no-op when `_isManualSourceConfigured()` is true; `onSourceChanged()` clears cache and stops in-flight GPS when switching to manual
- [x] T012 [ASYNC] [US2] Source change takes effect on next `refresh()` call automatically (reads storage each time); `onSourceChanged()` available for callers to force immediate cache invalidation

**Checkpoint**: US2 fully functional — source toggle correctly gates GPS hardware use and changes calculation input.

---

## Phase 5: User Story 3 — Location Source Indicator on Main View (Priority: P2)

**Goal**: A compact location indicator on the main screen always shows whether GPS or manually configured coordinates are in use.

**Independent Test**: With source = "Manual" and valid coords, verify main view shows "Manual" label (or coordinate summary). Switch to source = "GPS", verify indicator reverts to GPS status. Set source = "Manual" with no coords, verify indicator shows "No location set" and times show "--".

### Implementation for User Story 3

- [x] T013 [ASYNC] [US3] String keys `LocationIndicatorManual` and `ManualLocNoCoords` added to `resources/strings/shabbat_strings.xml`; GPS path reuses existing `GpsAcquiring` / `LocationNeeded` strings
- [x] T014 [SYNC] [US3] Extended `src/ui/TimeDisplayView.mc` Row 5: manual-no-coords → red "Set lat/lon first"; manual-with-coords → gray "Manual"; GPS-acquiring → yellow "GPS: acquiring…"; GPS-no-location → red "Set location"; existing polar warning + parasha paths preserved

**Checkpoint**: US3 functional — main view clearly communicates which location source is active.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Edge case hardening and final validation

- [x] T015 [P] [ASYNC] Polar-region warning preserved in `TimeDisplayView.mc` Row 5 — existing `PolarWarning` path remains intact in the `else if (_astronomicalService...)` branch; `LocationValidator.isPolarRegion()` also shown inline in settings lat row
- [x] T016 [P] [ASYNC] Verified `BatteryConservationService.mc` — `setUpdateIntervalSeconds()` calls on LocationService are harmless no-ops in manual mode (GPS never starts, so rate-limit interval is irrelevant); no changes required
- [x] T017 [ASYNC] String audit complete — no hardcoded GPS/manual UI strings found outside resource files; all literal strings in LocationService are debug-only logger messages (not displayed to user)

---

## Phase 7: User Story 4 — GPS Location Capture to Manual Config (Priority: P1)

**Goal**: User can select "Capture from GPS" in the settings screen; the app fires a one-shot GPS fix, saves the acquired coordinates as the manual lat/lon, automatically switches source to "manual", and shows live status (Acquiring → Saved / Failed) — no manual degree-entry required.

**Independent Test**: In the Connect IQ Simulator with a simulated GPS fix, navigate to Settings → scroll to "Capture GPS" item → SELECT → verify the item label transitions to "Acquiring…" → after fix callback fires, verify lat/lon rows update to the captured coordinates, source row shows "Manual", and persisted values survive an app restart.

### Implementation for User Story 4

- [x] T018 [P] [ASYNC] [US4] Add GPS capture string keys to `resources/strings/shabbat_strings.xml`: `CaptureGpsLabel` ("Capture GPS"), `CapturingGpsLabel` ("Acquiring…"), `GpsCapturedLabel` ("GPS Saved!"), `GpsCaptureFailed` ("GPS failed")
- [x] T019 [SYNC] [US4] Extend `src/ui/TimeSettingsView.mc`: add `using Toybox.Position;` import; add `_gpsCaptureState as Lang.String` field (values: `"idle"`, `"acquiring"`, `"saved"`, `"failed"`); add `ITEM_CAPTURE_GPS = 8` constant and bump `ITEM_COUNT` to `9`; in `activateSelected()` case `ITEM_CAPTURE_GPS`: call `Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onGpsFix))`, set `_gpsCaptureState = "acquiring"`; update `_drawItems()` to render the correct label from `_gpsCaptureState` and dim the row while non-idle capture states are active
- [x] T020 [SYNC] [US4] Implement `onGpsFix(info as Position.Info)` public callback method in `src/ui/TimeSettingsView.mc`: persist lat/lon + `location_auto=false` directly via `StorageManager`; mirror into `_config` in-memory; set `_gpsCaptureState = "saved"` on success / `"failed"` on invalid fix or exception; call `WatchUi.requestUpdate()`

**Checkpoint**: US4 complete — user can acquire and save their current GPS location as manual coordinates without entering degrees manually.

---

## Phase 8: User Story 5 — Show Live GPS Coordinates in Settings (Priority: P2)

**Goal**: When location source is "GPS", the lat/lon rows in `TimeSettingsView` display the actual GPS-acquired (or cached) coordinates instead of the in-memory `_config` defaults (which are 0.0). Rows remain dimmed/read-only; SELECT on them in GPS mode is a no-op.

**Independent Test**: With source = "GPS" and a cached location (e.g. from a prior GPS fix), open Settings and scroll to the lat/lon rows — verify they show the real cached coordinates (e.g. 40°, -74°) rather than "0°". Verify pressing SELECT on the lat row does not change the value.

### Implementation for User Story 5

- [x] T021 [SYNC] [US5] Update `src/ui/TimeSettingsView.mc` — `_drawItems()`: in GPS mode reads `LocationCache` to show real cached coords (or `"--"` if no cache) in lat/lon rows using existing format strings; `activateSelected()`: ITEM_LOC_LAT and ITEM_LOC_LON break immediately when source is "gps" (read-only)

**Checkpoint**: US5 complete — settings screen gives the user full visibility into the coordinates actually driving calculations regardless of which source is active.

---

## Phase 9: User Story 6 — Load System Last-Known Location on Launch (Priority: P1)

**Goal**: When the app launches and source is "gps", immediately seed `LocationService` with the system's last-known GPS fix by calling `Position.getInfo()` synchronously inside `initialize()`. This gives instant location availability (for astronomical calculations) before any timer fires or fresh GPS acquisition completes. The existing `_loadFromCache()` path (our own 24 h `LocationCache`) is retained as a secondary seed; the system fix is preferred if both are available, as it may be fresher.

**Independent Test**: Launch the app in the Connect IQ Simulator immediately after it has a cached GPS position from a prior session. Verify `LocationService.hasLocation()` returns `true` immediately after `initialize()` completes — before any timer tick or `startGpsTracking()` call. Verify Row 2 of `TimeDisplayView` (sunrise/sunset) populates without a "GPS: acquiring…" flash.

### Implementation for User Story 6

- [ ] T022 [SYNC] [US6] Add `_loadSystemLastKnown()` private method to `src/services/LocationService.mc` — calls `Position.getInfo()` synchronously; if `posInfo != null` and `posInfo.position != null`, extracts `coords = posInfo.position.toDegrees()`, validates with `LocationValidator.isUsable(coords[0].toFloat(), coords[1].toFloat())`; if valid: sets `_lat`, `_lon`, `_hasLocation = true`, `_source = "gps_system"`, and calls `new LocationCache().save(lat, lon)` to persist for future restarts; call `_loadSystemLastKnown()` from `initialize()` after `_loadFromCache()` (system fix overwrites stale cache if it differs); skip entirely when `_isManualSourceConfigured()` is true

**Checkpoint**: US6 complete — location is available from the very first frame of the app without a visible "acquiring…" state for users who have previously obtained a GPS fix.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion (T001) — **BLOCKS all user stories**
- **User Stories (Phases 3–5)**: All depend on Phase 2 completion (T002–T004)
  - US1 (Phase 3) and US2 (Phase 4) are both P1 and can be worked in parallel once Phase 2 is done
  - US3 (Phase 5) can begin after Phase 2; independent of US1/US2 for implementation, but logically follows US2
- **Polish (Phase 6)**: Depends on Phases 3–5 completion

### User Story Dependencies

- **US1 (P1)**: Requires Phase 2 → delivers coordinate entry and persistence
- **US2 (P1)**: Requires Phase 2; **also requires T003 (ConfigService) to be complete** to read locationSource — can start in parallel with US1
- **US3 (P2)**: Requires Phase 2; logically benefits from US2 (source toggle) but `TimeDisplayView` change is independent
- **US4 (P1)**: Requires Phase 2 (StorageManager, LocationValidator); T018 [P] with T019; T019 before T020 (both in `TimeSettingsView.mc`, sequential)
- **US5 (P2)**: Requires Phase 2 (LocationCache); independent of US4 but logically sequenced after it since T021 also touches `TimeSettingsView.mc` — run after T020 to avoid conflicts
- **US6 (P1)**: Requires Phase 2 (LocationCache, LocationValidator); only touches `LocationService.mc`; fully independent of US1–US5 and can run in parallel with any of them

### Within Each Phase

- T002 (model extension) before T003 and T004 (they depend on updated TimeConfiguration)
- T003 and T004 can run in parallel [P] after T002
- T005 (strings) before T006 and T007 (they reference the keys) — or strings can be added inline during component creation
- T006 (LocationSettingsComponent) before T008 (TimeSettingsView integrates it)
- T007 (layout XML) before T008 (TimeSettingsView uses layout)
- T010 (getLocation branching) before T011 (GPS suppression — both in LocationService, sequential)
- T011 before T012 (onSourceChanged must exist before it can be called)

---

## Parallel Execution Examples

### Phase 2 Parallel Group (after T002)

```
T003: Extend ConfigService (src/services/ConfigService.mc)
T004: Extend LocationValidator (src/lib/validation/LocationValidator.mc)
```

### Phase 3 + Phase 4 Parallel Start (after Phase 2)

```
Stream A (US1): T005 → T006 → T007 → T008 → T009
Stream B (US2): T010 → T011 → T012
```

### Phase 5 + 6 Parallel Group (after Phases 3–4)

```
T013 → T014 (US3 indicator)
T015, T016, T017 (polish — different files, fully parallel)
```

---

## Implementation Strategy

### MVP (US1 + US2 — both P1)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T004)
3. Complete Phase 3: US1 Manual Entry (T005–T009)
4. Complete Phase 4: US2 Source Toggle (T010–T012)
5. **STOP and VALIDATE**: Test with New York coords — verify times, persistence, GPS suppression
6. Ship MVP

### Incremental Delivery

1. Setup + Foundational → storage keys and model ready
2. US1 → users can enter and persist coordinates
3. US2 → location source selection actively drives calculations
4. US3 → main view reflects the active source (transparency)
5. Polish → edge cases and string cleanup

---

## Task Count Summary

| Phase | Tasks | Stories |
|-------|-------|---------|
| Phase 1: Setup | 1 | — |
| Phase 2: Foundational | 3 | — |
| Phase 3: US1 (P1) | 5 | US1 |
| Phase 4: US2 (P1) | 3 | US2 |
| Phase 5: US3 (P2) | 2 | US3 |
| Phase 6: Polish | 3 | — |
| Phase 7: US4 (P1) | 3 | US4 |
| Phase 8: US5 (P2) | 1 | US5 |
| Phase 9: US6 (P1) | 1 | US6 |
| **Total** | **22** | **6 stories** |

**MVP scope**: Phases 1–4 (T001–T012) + Phase 7 (T018–T020)  
**Parallel opportunities**: T003‖T004, Phase 3‖Phase 4, T015‖T016‖T017, T018‖[T019→T020]  
**[SYNC] tasks** (require human review): T002, T006, T008, T010, T011, T014, T019, T020, T021, T022 (10 tasks)  
**[ASYNC] tasks** (agent-delegable): T001, T003, T004, T005, T007, T009, T012, T013, T015, T016, T017, T018 (12 tasks)
