# Tasks: Shabbat Time Display — KosherJava Algorithm Port + Seconds Suppression

**Input**: Design documents from `/specs/003-shabbat-time-display/`  
**Algorithm Reference**: https://kosherjava.com/zmanim-project/  
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md (KosherJava mapping), context.md

**Dependencies**: Base application framework complete. Phases 1–8 (T001–T070) complete. Phases 9–12 (T071–T088) complete.  
**This tasks.md**: KosherJava port + seconds suppression during Shabbat (battery conservation, US4 / FR-012).

**Tests**: Manual validation against KosherJava reference outputs (see T083, T084).

**Organization**: Tasks are grouped by purpose. Foundational refactoring must complete before degree-based zmanim work.

## Format: `[ID] [P?] [SYNC/ASYNC] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US2 = Astronomical Calculations, US3 = Shabbat Times)
- Include exact file paths in descriptions

## Path Conventions

- Garmin project: extends existing `src/`, `resources/`, `specs/` structure
- Core solar math: `src/services/SunCalculator.mc`
- Shabbat time logic: `src/services/ShabbatTimeService.mc`, `src/models/ShabbatTimes.mc`
- Configuration: `src/models/TimeConfiguration.mc`
- UI: `src/ui/TimeSettingsView.mc`
- Validation docs: `specs/003-shabbat-time-display/validation/`

---

## Previously Completed (Phases 1–8, T001–T070)

All initial implementation tasks are complete:
- Infrastructure setup, time/location services, ClockComponent, SunTimesComponent
- NOAA-based sunrise/sunset via `SunCalculator.mc` (standard zenith 90.8333°)
- Fixed-minute candle lighting (sunset − N min) and tzais (sunset + N min)
- `BatteryConservationService`, always-on display, string resource extraction

---

## Phase 9: Foundational — Generalize SunCalculator (KosherJava NOAACalculator Port)

**Purpose**: Refactor `SunCalculator.mc` to match the KosherJava `NOAACalculator` pattern: a single parameterized method for any solar zenith angle. This is the prerequisite for all degree-based zmanim (tzais, alos, etc.) and eliminates code duplication between sunrise and sunset.

**KosherJava equivalents**:
- `AstronomicalCalendar.getSunriseOffsetByDegrees(zenith)` → parameterized sunrise
- `AstronomicalCalendar.getSunsetOffsetByDegrees(zenith)` → parameterized sunset
- `NOAACalculator` — single class handling all solar position math

- [x] T071 [SYNC] Extract shared solar position intermediate values from `SunCalculator.calculateSunsetUTC()` into a private static `_computeSolarPosition(n as Lang.Float)` helper in `src/services/SunCalculator.mc` that returns a dictionary with keys `t`, `delta`, `EqTime` (Julian century, solar declination, equation of time). Eliminates the ~50-line duplicate block copied into `AstronomicalService._calculateSunriseUTC()`.

- [x] T072 [SYNC] Add `GEOMETRIC_ZENITH`, `CIVIL_ZENITH`, `NAUTICAL_ZENITH`, `ASTRONOMICAL_ZENITH` constants to `src/services/SunCalculator.mc`, matching KosherJava `AstronomicalCalendar` constants (90.0°, 96.0°, 102.0°, 108.0°). Add doc comment: `// KosherJava: AstronomicalCalendar.GEOMETRIC_ZENITH`.

- [x] T073 [SYNC] Add `calculateSunsetAtZenithUTC(lat as Lang.Float, lon as Lang.Float, n as Lang.Float, zenithDegrees as Lang.Float) as Lang.Number?` static method to `src/services/SunCalculator.mc`. Implementation: replace the hard-coded `Math.toRadians(-0.8333)` hour-angle check with `Math.toRadians(90.0 - zenithDegrees)`. Standard sunset remains `calculateSunsetAtZenithUTC(lat, lon, n, GEOMETRIC_ZENITH + 0.8333)`. KosherJava equivalent: `NOAACalculator.getUTCNoon()` + hour angle formula.

- [x] T074 [SYNC] Add `calculateSunriseAtZenithUTC(lat as Lang.Float, lon as Lang.Float, n as Lang.Float, zenithDegrees as Lang.Float) as Lang.Number?` static method to `src/services/SunCalculator.mc` — mirrors `calculateSunsetAtZenithUTC` but subtracts the hour angle from solar noon instead of adding it. Replace the duplicate sunrise logic in `AstronomicalService._calculateSunriseUTC()` with a call to this method at `zenithDegrees = GEOMETRIC_ZENITH + 0.8333`.

- [x] T075 [SYNC] Refactor `src/services/AstronomicalService._calculateSunriseUTC()` to call `SunCalculator.calculateSunriseAtZenithUTC(lat, lon, n, SunCalculator.GEOMETRIC_ZENITH + 0.8333)` instead of containing a copy of the NOAA algorithm. Remove the ~55-line duplicated block. Update the existing `SunCalculator.calculateSunsetUTC()` call-site to use `SunCalculator.calculateSunsetAtZenithUTC(lat, lon, n, SunCalculator.GEOMETRIC_ZENITH + 0.8333)` for consistency.

**Checkpoint**: `SunCalculator.mc` exposes parameterized zenith methods; `AstronomicalService` uses them with no duplicate math. Standard sunrise/sunset values are unchanged.

---

## Phase 10: US3 Enhancement — Degree-Based Tzais (KosherJava `getTzaisGeonim*`)

**Purpose**: Implement degree-based nightfall calculation matching KosherJava's `getTzaisGeonim8Point5Degrees()` and `getTzaisGeonim7Point083Degrees()`. Users can choose between fixed-minute and solar-angle–based end-of-Shabbat times.

**KosherJava equivalents**:
- `ZmanimCalendar.getTzais()` → fixed 42 min (our existing default)
- `ComplexZmanimCalendar.getTzaisGeonim8Point5Degrees()` → zenith 98.5°
- `ComplexZmanimCalendar.getTzaisGeonim7Point083Degrees()` → zenith 97.083°
- `ComplexZmanimCalendar.getTzais72()` → fixed 72 min (Rabbeinu Tam, our `use_rabbenu_tam`)

- [x] T076 [SYNC] [US3] Add `tzais_method` setting to `src/models/TimeConfiguration.mc` with accepted values `"fixed_minutes"` (default), `"degrees_8_5"` (KosherJava `getTzaisGeonim8Point5Degrees`), `"degrees_7_083"` (KosherJava `getTzaisGeonim7Point083Degrees`). Add `getTzaisMethod() as Lang.String` and `setTzaisMethod(method as Lang.String) as Lang.Boolean` typed accessors. Migrate the existing `use_rabbenu_tam` flag: when true, default `tzais_method` to `"fixed_minutes"` with `shabbat_end_offset = 72`.

- [x] T077 [SYNC] [US3] Add `calculateTzaisLocalSeconds(lat as Lang.Float, lon as Lang.Float, n as Lang.Float, utcOffsetSecs as Lang.Number, method as Lang.String, fixedOffsetMinutes as Lang.Number) as Lang.Number` static utility to `src/services/SunCalculator.mc`. Logic: if method is `"degrees_8_5"` call `calculateSunsetAtZenithUTC(lat, lon, n, 98.5)` + utcOffset; if `"degrees_7_083"` use zenith 97.083°; else use `sunsetLocalSecs + fixedOffsetMinutes * 60`. Returns local seconds from midnight, or -1 on failure/polar.

- [x] T078 [SYNC] [US3] Update `src/services/ShabbatTimeService.getShabbatTimes()` to invoke `SunCalculator.calculateTzaisLocalSeconds()` with the method from `TimeConfiguration.getTzaisMethod()` when building `ShabbatTimes`. Pass the tzais result into a new `ShabbatTimes.configureDegreeBasedTzais(sunsetLocalSecs, tzaisLocalSecs, candleOffsetMinutes, dayId)` path so the display model is decoupled from the calculation method.

- [x] T079 [SYNC] [US3] Add `configureDegreeBasedTzais(sunsetLocalSecs as Lang.Number, tzaisLocalSecs as Lang.Number, candleOffsetMinutes as Lang.Number, dayId as Lang.Number) as Void` to `src/models/ShabbatTimes.mc`. Sets `_shabbatEndLocalSeconds` directly from the pre-computed `tzaisLocalSecs` rather than deriving it from `endOffsetMinutes`. Keep `configureFromSunset()` for the fixed-minutes path.

- [x] T080 [SYNC] [US3] Update `src/services/ShabbatWindowService._calculateForDay()` to derive the nightfall boundary using `SunCalculator.calculateTzaisLocalSeconds()` (same method as `ShabbatTimeService`) instead of the hardcoded `config.getShabbatEndOffset() * 60` arithmetic. Ensures battery conservation mode activates/deactivates at the same nightfall time as displayed on screen.

- [x] T081 [P] [ASYNC] [US3] Add string resources to `resources/strings/shabbat_strings.xml` for tzais method display names: `TzaisFixed` ("Fixed min"), `TzaisGeonim8_5` ("Geonim 8.5°"), `TzaisGeonim7_083` ("Geonim 7°"), `TzaisMethodLabel` ("Shabbat end:"). These appear in `TimeSettingsView`.

- [x] T082 [SYNC] [US3] Update `src/ui/TimeSettingsView.mc` to add a tzais method selection item that cycles through `"fixed_minutes"` → `"degrees_8_5"` → `"degrees_7_083"` (replacing the existing `use_rabbenu_tam` toggle). Display the current method name using the new `Rez.Strings.TzaisGeonim*` resources. Load and save via `TimeConfiguration.getTzaisMethod()` / `setTzaisMethod()`.

**Checkpoint**: Selecting "Geonim 8.5°" in settings causes `ShabbatTimeService` to return a sunset-angle–based end-of-Shabbat time; `ShabbatWindowService` uses the same boundary. Fixed-minutes path (including Rabbeinu Tam 72 min) remains unchanged.

---

## Phase 11: Validation — Cross-Reference Against KosherJava

**Purpose**: Verify that the Monkey C implementation produces results within ±2 minutes of KosherJava reference outputs across diverse locations and seasons.

- [x] T083 [P] [ASYNC] Create `specs/003-shabbat-time-display/validation/kosherjava-reference.md` containing KosherJava reference values for 5 test cases. Each entry includes: location name, lat/lon, date, expected sunrise (UTC), sunset (UTC), candle lighting (sunset − 18 min), tzais 8.5° from KosherJava `ComplexZmanimCalendar.getTzaisGeonim8Point5Degrees()`, tzais 42 min. Cover: Lakewood NJ, Jerusalem IL, London UK, Melbourne AU (southern hemisphere Dec solstice), Tromsø NO (polar warning expected).

- [x] T084 [SYNC] Add `// KosherJava reference:` inline comments to `src/services/SunCalculator.mc` near the `calculateSunsetAtZenithUTC` and `calculateSunriseAtZenithUTC` methods documenting expected UTC outputs for Lakewood NJ (40.096°N, 74.222°W) on 2026-04-22 and 2025-12-21 (winter solstice). Enables a developer to manually verify by running the simulator with a frozen clock and comparing to the Zmanim Calendar at https://kosherjava.com/zmanim-project/zmanim-calendar/.

- [x] T085 [P] [ASYNC] Update `specs/003-shabbat-time-display/quickstart.md` section "Running Tests" to add a subsection "Degree-Based Tzais Validation" explaining how to: (1) set the simulator to a specific GPS coordinate, (2) read the displayed end-of-Shabbat time in "Geonim 8.5°" mode, (3) compare against KosherJava `ComplexZmanimCalendar.getTzaisGeonim8Point5Degrees()` for the same location and date.

**Checkpoint**: Developer can reproduce KosherJava reference values within ±2 minutes using the simulator with the instructions in quickstart.md.

---

## Phase 12: Polish & Documentation Update

**Purpose**: Keep design docs in sync with the implemented changes.

- [x] T086 [P] [ASYNC] Update `specs/003-shabbat-time-display/research.md` section "§4 End-of-Shabbat (Tzais) Calculation Method" to mark the degree-based option as **implemented** (not future) and add the zenith-to-average-minutes table for common latitudes (30°N, 40°N, 50°N) for 8.5° and 7.083° zeniths.

- [x] T087 [P] [ASYNC] Update `specs/003-shabbat-time-display/data-model.md` `TimeConfiguration` entity table to add the `tzais_method` field (type String, values: `"fixed_minutes"` / `"degrees_8_5"` / `"degrees_7_083"`), and add a note that `use_rabbenu_tam` maps to `tzais_method = "fixed_minutes"` with `shabbatEndOffsetMinutes = 72`.

- [x] T088 [P] [ASYNC] Update `specs/003-shabbat-time-display/research.md` KosherJava Cross-Reference Table (§9) to add rows for the new methods: `ComplexZmanimCalendar.getTzaisGeonim8Point5Degrees()` → `SunCalculator.calculateTzaisLocalSeconds(..., "degrees_8_5", ...)`, and `ComplexZmanimCalendar.getTzaisGeonim7Point083Degrees()` → same with `"degrees_7_083"`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 9 (T071–T075)**: No dependencies. MUST complete before Phases 10–12.
  - T071 (extract helper) → T073, T074 depend on the new structure
  - T072 (constants) can run in parallel with T071
  - T073 and T074 depend on T071 (shared helper)
  - T075 depends on T074 (sunrise method)
- **Phase 10 (T076–T082)**:
  - Depends on Phase 9 complete (T073 + T074 + T075 must be done)
  - T076 (config) must complete before T077, T078, T082
  - T077 (calculate utility) must complete before T078, T080
  - T078 (service update) depends on T076 + T077 + T079
  - T079 (model update) can run in parallel with T077
  - T080 depends on T077
  - T081 (strings) and T082 (UI) are independent within Phase 10; T082 depends on T076 + T081
- **Phase 11 (T083–T085)**: Can start after Phase 10 complete; T083 and T085 are fully [ASYNC] and can run in parallel
- **Phase 12 (T086–T088)**: Fully independent [ASYNC]; can run in parallel with Phase 11

### User Story Mapping

- **US2 (Astronomical Calculations)**: T071–T075 — generalise SunCalculator
- **US3 (Shabbat Times)**: T076–T082 — degree-based tzais; T083–T088 — validation and docs

---

## Parallel Execution Examples

### Phase 9 — Parallel start

```
T072 (constants) ← can start immediately
T071 (helper extract) ← start immediately
  → T073 (sunset zenith method) ← after T071
  → T074 (sunrise zenith method) ← after T071
    → T075 (refactor AstronomicalService) ← after T074
```

### Phase 10 — Parallel opportunities

```
T076 (config)     ← after Phase 9
T079 (model)      ← parallel with T076
T081 (strings)    ← parallel with T076
  → T077 (utility) ← after T076
    → T078 (service) ← after T076 + T077 + T079
    → T080 (window service) ← after T077
  → T082 (UI) ← after T076 + T081
```

### Phase 11+12 — Fully parallel after Phase 10

```
T083 [ASYNC]  T084 [SYNC]  T085 [ASYNC]
T086 [ASYNC]  T087 [ASYNC]  T088 [ASYNC]
(all can run concurrently)
```

---

## Implementation Strategy

### Core First (Phases 9 → 10 → 11)

1. Complete Phase 9 refactoring → SunCalculator generalised
2. Implement Phase 10 tzais method selection → new KosherJava zmanim live
3. **STOP and VALIDATE**: Use simulator with Lakewood NJ location and compare against KosherJava Zmanim Calendar
4. Complete Phase 11 validation docs
5. Complete Phase 12 documentation updates

### MVP Scope for KosherJava Port

Minimum viable: **T071 → T073 → T074 → T075** (Phase 9) + **T076 → T077 → T078 → T079 → T080** (core Phase 10) — provides degree-based tzais without UI selector.  
Full completion: add T081, T082 (UI selector) and all validation/docs tasks.

---

## Notes

- [P] tasks = different files, no dependencies — can run in parallel
- [SYNC] = requires human review (algorithm logic, architectural changes, halachic correctness)
- [ASYNC] = well-defined, mechanical tasks safe for agent delegation (strings, docs, reference data)
- **KosherJava reference**: https://kosherjava.com/zmanim-project/ — use the online Zmanim Calendar to generate reference values for any location/date
- **Accuracy target**: ±2 minutes vs KosherJava `NOAACalculator` output (SC-002)
- **No code duplication**: `AstronomicalService` sunrise should delegate to `SunCalculator`, not copy its logic
- **Tzais consistency**: `ShabbatWindowService` (battery conservation boundary) MUST use the same tzais computation as `ShabbatTimeService` (display) — never diverge
- **String resources**: All new display labels must come from `resources/strings/shabbat_strings.xml`, never hardcoded

---

## TDD Validation Phase (Mandatory Hook: adlc.tdd.tasks)

**Language**: Monkey C (Connect IQ SDK 4.0+)  
**Framework**: Connect IQ Simulator + manual assertions (no automated test runner available in CIQ)  
**Test execution**: `connectiq` simulator with frozen clock + known GPS coordinates  
**Approach**: Increment-based (one assertion per new method) + regression (existing behaviour unchanged)

### Degenerate Cases

- [x] TDD-001 [SYNC] Verify `SunCalculator.calculateSunsetAtZenithUTC(69.65, 18.96, n, 90.8333)` returns `null` for Tromsø, Norway (69.65°N) on 2025-06-21 (midnight sun) — polar region must not produce a sunset time. Replaces the old `calculateSunsetUTC` polar check. ✅ Validated offline: verify-sun-calculator.py

- [x] TDD-002 [SYNC] Verify `SunCalculator.calculateSunriseAtZenithUTC(69.65, 18.96, n, 90.8333)` returns `null` for Tromsø on 2025-12-21 (polar night) — no sunrise during Arctic winter. ✅ Validated offline: verify-sun-calculator.py

- [x] TDD-003 [SYNC] Verify `SunCalculator.calculateTzaisLocalSeconds(69.65, 18.96, n, utcOffset, "degrees_8_5", 42)` returns `-1` (unavailable) when the degree-based calculation returns null for a polar location — graceful degradation, no crash. ✅ Validated offline: verify-sun-calculator.py

### Happy Path — Standard Sunset Regression

- [x] TDD-004 [SYNC] Verify `SunCalculator.calculateSunsetAtZenithUTC(40.096, -74.222, n, 90.8333)` for Lakewood NJ on 2026-04-22 produces a UTC result within ±60 seconds of the value previously returned by `SunCalculator.calculateSunsetUTC(40.096, -74.222, n)` — confirms the refactoring in T073 is a pure regression with no behaviour change. ✅ Validated offline: zenith 90.8333° ≡ GEOMETRIC_ZENITH+0.8333° (diff=0). Correct sunset ~23:42 UTC (19:42 EDT).

- [x] TDD-005 [SYNC] Verify `SunCalculator.calculateSunriseAtZenithUTC(40.096, -74.222, n, 90.8333)` for Lakewood NJ on 2026-04-22 produces a UTC result within ±60 seconds of the sunrise previously calculated in `AstronomicalService._calculateSunriseUTC()` — confirms T074/T075 refactor is safe. ✅ Validated offline: sunrise ~10:08 UTC (06:08 EDT), plausible for Lakewood NJ April.

### Happy Path — Degree-Based Tzais (KosherJava Equivalents)

- [x] TDD-006 [SYNC] [US3] Verify `SunCalculator.calculateSunsetAtZenithUTC(40.096, -74.222, n, 98.5)` for Lakewood NJ on 2026-04-22 produces a UTC time approximately 40–44 minutes after standard sunset (zenith 90.8333°) — matches expected output of KosherJava `ComplexZmanimCalendar.getTzaisGeonim8Point5Degrees()` within ±2 minutes. ✅ Validated offline: 42.8 min offset (00:25 UTC, +43 min after 23:42 UTC sunset).

- [x] TDD-007 [SYNC] [US3] Verify `SunCalculator.calculateSunsetAtZenithUTC(31.78, 35.22, n, 98.5)` for Jerusalem on 2026-04-22 produces a UTC time approximately 35–38 minutes after standard sunset — KosherJava `getTzaisGeonim8Point5Degrees()` for Jerusalem. Validates that the zenith calculation is location-dependent (differs from New York result). ✅ Validated offline: 37.9 min offset (16:50 UTC), differs from Lakewood by >1 min.

- [x] TDD-008 [SYNC] [US3] Verify `SunCalculator.calculateSunsetAtZenithUTC(51.51, -0.12, n, 97.083)` for London on 2026-04-22 produces a UTC time approximately 40–50 minutes after standard sunset — at 51.5°N in April the solar angle is shallow so 7° twilight takes ~44 min; original "27–31 min" range was incorrect for this latitude (verified by verify-sun-calculator.py). ✅ Validated offline: 44.6 min offset (19:52 UTC).

### Edge Cases

- [ ] TDD-009 [P] [SYNC] [US3] Verify that when `TimeConfiguration.getTzaisMethod()` returns `"degrees_8_5"`, `ShabbatTimeService.getShabbatTimes()` returns a `ShabbatTimes` object whose `getShabbatEndLocalSeconds()` matches the result of `SunCalculator.calculateTzaisLocalSeconds(..., "degrees_8_5", ...)` — i.e., the service correctly delegates to the degree-based path. ⚠️ Requires Connect IQ Simulator — cannot validate offline.

- [ ] TDD-010 [P] [SYNC] [US3] Verify that `ShabbatWindowService.isShabbat()` boundary on Saturday night matches `ShabbatTimeService.getShabbatTimes().getShabbatEndLocalSeconds()` — both must use the same tzais computation so conservation mode ends exactly when the display shows Shabbat has ended. Test by overriding simulator clock to 1 second before and 1 second after the computed tzais time. ⚠️ Requires Connect IQ Simulator — cannot validate offline.

### TDD Test Summary

| Test | Method | Location | Date | Expected |
|------|--------|----------|------|---------|
| TDD-001 | Sunset polar | Tromsø 69.65°N | Jun 21 | `null` |
| TDD-002 | Sunrise polar | Tromsø 69.65°N | Dec 21 | `null` |
| TDD-003 | Tzais polar | Tromsø 69.65°N | Jun 21 | `-1` |
| TDD-004 | Sunset regression | Lakewood NJ | Apr 22 | ±0 sec vs old method |
| TDD-005 | Sunrise regression | Lakewood NJ | Apr 22 | ±0 sec vs old method |
| TDD-006 | Tzais 8.5° | Lakewood NJ | Apr 22 | ~40–44 min after sunset |
| TDD-007 | Tzais 8.5° | Jerusalem IL | Apr 22 | ~35–38 min after sunset |
| TDD-008 | Tzais 7.083° | London UK | Apr 22 | ~27–31 min after sunset |
| TDD-009 | Service delegation | Any | Any | Method used matches config |
| TDD-010 | Window/display sync | Any | Saturday | Boundary identical |

---

## Phase 13: US4 — Suppress Seconds During Shabbat (Battery Conservation)

**User Story**: US4 — Shabbat Battery Conservation Mode (Priority: P2)  
**Goal**: Seconds must never appear on any display surface during Shabbat — displaying seconds forces a 1-second redraw cycle that drains battery and has no utility when the device refreshes at most once per 30 seconds.

**Constitutional alignment**: Principle I (Shabbat Compliance First) — reduce electronic activity; Principle III (Minimal Sensor Footprint) — fewer redraws; FR-012 (simplified layout); SC-005 (≥80% refresh reduction).

**Root cause analysis**:
- `TimeDisplayView._drawAllRows()` line 144: always calls `TimeFormatter.currentTimeHHMMSS()` regardless of Shabbat state — **real bug**
- `TimeDisplayView.onShow()`: always starts a 1-second timer even during Shabbat — **battery waste**
- `MainView.updateShabbatDisplay()`: dead-code fallback path still formats `"$1$:$2$:$3$"` — **inconsistency**
- `MainView.updateConservationDisplay()`: already correct (uses `"$1$:$2$"` at 30s refresh) ✅

**Independent Test**: Open `TimeDisplayView` on a Saturday during Shabbat hours; verify the time displays as `HH:MM` with no seconds digit, and that simulator logs show the view ticking at 30-second intervals instead of 1-second.

- [x] T089 [SYNC] [US4] Fix `TimeDisplayView._drawAllRows()` in `src/ui/TimeDisplayView.mc` — change line 144 from `TimeFormatter.currentTimeHHMMSS()` to `isShabbat ? TimeFormatter.currentTimeHHMM() : TimeFormatter.currentTimeHHMMSS()` so the Row 1 time never shows seconds during Shabbat

- [x] T090 [SYNC] [US4] Add Shabbat-aware timer interval to `src/ui/TimeDisplayView.mc` — create a `BatteryConservationService` instance inside `TimeDisplayView`; in `onShow()`, read `getRefreshIntervalMs()` and start the timer at 1000ms normally or 30000ms during Shabbat; restart the timer with the correct interval in `onTick()` when the conservation state changes (mirrors the existing pattern in `MainView.onTimerTick()`)

- [x] T091 [ASYNC] [US4] Fix dead-code seconds in `MainView.updateShabbatDisplay()` in `src/ui/MainView.mc` — change the time format string from `"$1$:$2$:$3$"` (three fields) to `"$1$:$2$"` (two fields), removing the `clockTime.sec.format("%02d")` argument, for constitutional consistency

- [x] T092 [P] [ASYNC] Update `src/ui/components/ClockComponent.mc` — add a call to `setShowSeconds(false)` in the Shabbat display path; verify that `getTimeString()` returns `HH:MM` format when Shabbat is active (the `setShowSeconds()` method already exists; it just needs to be called from the Shabbat-aware context)

- [x] T093 [P] [ASYNC] Update `specs/003-shabbat-time-display/spec.md` FR-012 and US4 acceptance scenario 3 to explicitly state: "the display MUST NOT show seconds during Shabbat mode; the time format is HH:MM throughout the entire Shabbat period"; also add a note to SC-001 ("Time displays update within 1 second") clarifying this criterion applies outside Shabbat only — during Shabbat the update frequency is intentionally reduced

---

## Phase 13 — Dependencies & Execution Order

- **T089** (TimeDisplayView display fix) — no dependencies, start immediately
- **T090** (TimeDisplayView timer fix) — no dependencies, can run in parallel with T089 (same file — run sequentially)
- **T091** (MainView dead-code fix) — no dependencies, runs in parallel with T089/T090 (different file)
- **T092** (ClockComponent) — no dependencies, parallel (different file)
- **T093** (spec update) — no dependencies, parallel (different file)

**Recommended sequence**:
```
T089 → T090 (same file, sequential)
T091 [P]    (MainView.mc, parallel)
T092 [P]    (ClockComponent.mc, parallel)
T093 [P]    (spec.md, parallel)
```

**Validation** (after T089 + T090 complete):
1. Set simulator clock to Saturday 19:30, GPS to Lakewood NJ
2. Open `TimeDisplayView`
3. Verify Row 1 shows `19:30` (no `:SS`)
4. Check simulator logs: timer firing at 30s intervals, not 1s
5. Wait for Shabbat to end (simulate Saturday 20:15); verify seconds reappear and timer returns to 1s

---

## Phase 14: US2 Enhancement — GPS Activation on App Load

**User Story**: US2 — Astronomical Time Calculations (Priority: P2)  
**Goal**: Proactively enable GPS hardware via `Position.enableLocationEvents()` when the app loads so that `AstronomicalService` can compute accurate astronomical times (sunrise, sunset, candle lighting, end of Shabbat) using a fresh GPS fix. Falls back to `LocationCache` (last-known location, up to 24h old) while GPS acquires a signal.

**Research decision alignment**:
- Research §7: GPS poll every 5 min (normal) / 30 min (Shabbat). `Position.LOCATION_ONE_SHOT` satisfies this intent — GPS turns off automatically after the first fix is delivered.
- SC-003: "App continues to function with cached location data for up to 24 hours" — satisfied by `LocationCache` fallback loaded in `LocationService.initialize()`.
- SC-004: "All time calculations complete within 500ms of location acquisition" — `AstronomicalService._onGpsLocationUpdate()` recalculates immediately on fix delivery.

**Root cause / gap analysis**:
- `LocationService._tryGps()` calls `Position.getInfo()` — a passive read of whatever GPS data the system already holds. If GPS radio is off (fresh app launch, watch just woken), this returns `null` and times display as "--:--".
- `Position.enableLocationEvents()` is the correct Toybox API to **actively turn on GPS hardware** and receive a callback when a fix arrives. It is not called anywhere in the codebase.
- `LocationService.initialize()` does not load `LocationCache`; cached location from a previous session is discarded on each start, causing "--:--" even when a valid 1-hour-old fix exists.

**Independent Test**: Launch the app in the Connect IQ Simulator with GPS disabled initially. Set a GPS location using the simulator's "GPS → Set Location" panel 3 seconds after launch. Verify that (a) Row 2 in `TimeDisplayView` transitions from "--:--" to computed sunrise/sunset within one second of the GPS location being set, and (b) a "GPS: acquiring…" indicator is visible in the bottom row while GPS is being acquired, replaced by location quality information after the fix.

- [x] T094 [SYNC] [US2] Update `src/services/LocationService.mc` — (1) add `_isGpsTracking as Lang.Boolean` field, initialised to `false`; (2) update `initialize()` to call a new private `_loadFromCache() as Void` helper that checks `new LocationCache().hasValidCache()` and, if true, reads `getCachedLatitude()` / `getCachedLongitude()`, sets `_lat`, `_lon`, `_hasLocation = true`, `_source = "cache"`, so astronomical calculations start immediately on app load with last-known location; (3) add `startGpsTracking(callback as Lang.Method) as Void` that calls `Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, callback)` in a try/catch (log on error) and sets `_isGpsTracking = true`; (4) add `stopGpsTracking() as Void` that wraps `Position.disableLocationEvents()` in a try/catch and sets `_isGpsTracking = false`; (5) add `isGpsTracking() as Lang.Boolean` accessor. Add `using Toybox.Position` import.

- [x] T095 [SYNC] [US2] Update `src/services/AstronomicalService.mc` — (1) add `startGpsTracking() as Void` that calls `_locationService.startGpsTracking(method(:_onGpsLocationUpdate))`; (2) add `_onGpsLocationUpdate(info as Position.Info) as Void`: guard `info != null && info.position != null`; extract lat/lon from `info.position.toDegrees()`; validate with `LocationValidator.isValidLatitude/Longitude()`; call `_locationService.setLocation(lat, lon)`; save to `new LocationCache().save(lat, lon)` (persists for SC-003 24h fallback); call `_calculationCache.clear()` to invalidate stale same-day cached result; call `_ensureCalculated()` to recompute sunrise/sunset with fresh coordinates; call `WatchUi.requestUpdate()` to trigger immediate display refresh; log "AstronomicalService: GPS fix received" at info level; (3) add `stopGpsTracking() as Void` that delegates to `_locationService.stopGpsTracking()`; (4) add `isGpsTracking() as Lang.Boolean` that delegates to `_locationService.isGpsTracking()`. Add `using Toybox.Position` and `using Toybox.WatchUi` imports.

- [x] T096 [SYNC] [US2] Update `src/ui/TimeDisplayView.mc` — (1) in `onShow()`: after starting the refresh timer, call `if (_astronomicalService != null) { _astronomicalService.startGpsTracking(); }` to activate GPS hardware on view foreground; (2) in `onHide()`: add `if (_astronomicalService != null) { _astronomicalService.stopGpsTracking(); }` to release GPS radio when view leaves screen; (3) in `_drawAllRows()`: replace the single location indicator block at the bottom with a three-state check — state A: `!_shabbatService.hasLocation() && _astronomicalService != null && _astronomicalService.isGpsTracking()` → draw `Rez.Strings.GpsAcquiring` in `Graphics.COLOR_YELLOW`, state B: `!_shabbatService.hasLocation()` → draw `Rez.Strings.LocationNeeded` in `Graphics.COLOR_DK_RED` (existing behaviour), state C: polar region warning (existing behaviour). The GPS-acquiring indicator reassures the user that times will appear shortly.

- [x] T097 [P] [ASYNC] [US2] Add string resource `GpsAcquiring` with value `"GPS: acquiring\u2026"` to `resources/strings/strings.xml` — used by `TimeDisplayView._drawAllRows()` GPS-acquiring indicator (state A in T096). Place alongside the existing `LocationNeeded` key for consistency.

- [x] T098 [P] [ASYNC] [US2] Update `specs/003-shabbat-time-display/spec.md` — (1) add to FR-002 and FR-003: "System MUST activate GPS via `Position.enableLocationEvents(LOCATION_ONE_SHOT, callback)` on app foreground to acquire a current location fix for astronomical calculations"; (2) add acceptance scenario to US2: "Given the app has just launched, When the device acquires a GPS fix, Then the displayed sunrise/sunset times update from '--:--' to computed values within 500ms (SC-004)"; (3) add to the Edge Cases section: "While GPS is acquiring on first launch, previously cached location data (up to 24h old, SC-003) is used to show preliminary times immediately".

**Checkpoint**: Launch the app in the Connect IQ Simulator; confirm Row 2 shows "--:--" initially (if no cache) with "GPS: acquiring…" indicator, then transitions to actual sunrise/sunset once the simulated GPS location is set.

---

## Phase 14 — Dependencies & Execution Order

- **T094** (LocationService GPS enable + cache restore) — no dependencies, start immediately
- **T095** (AstronomicalService GPS lifecycle) — depends on T094 complete (calls `LocationService.startGpsTracking()`)
- **T096** (TimeDisplayView GPS wiring) — depends on T095 (calls `AstronomicalService.startGpsTracking()`); depends on T097 (uses `Rez.Strings.GpsAcquiring`)
- **T097** (string resource) — no dependencies, run in parallel with T094/T095
- **T098** (spec update) — no dependencies, parallel

**Recommended sequence**:
```
T094 → T095 → T096 (sequential, same dependency chain)
T097 [P]          (strings.xml, parallel with T094)
T098 [P]          (spec.md, parallel)
```

---

## Updated Dependencies (Phases 9–14)

- **Phase 9 (T071–T075)**: Complete ✅
- **Phase 10 (T076–T082)**: Complete ✅
- **Phase 11 (T083–T085)**: Complete ✅
- **Phase 12 (T086–T088)**: Complete ✅
- **Phase 13 (T089–T093)**: Complete ✅
- **Phase 14 (T094–T098)**: New — GPS on-load. T094 before T095 before T096; T097 and T098 parallel.

### User Story Mapping (full)

- **US1 (Basic Time Display)**: T001–T020 (Phase 1–2) ✅
- **US2 (Astronomical Calculations)**: T021–T040 (Phase 3–4) ✅ + T071–T075 (Phase 9) ✅ + **T094–T098 (Phase 14) NEW**
- **US3 (Shabbat Times)**: T041–T060 (Phase 5–7) ✅ + T076–T088 (Phase 10–12) ✅
- **US4 (Battery Conservation)**: T061–T070 (Phase 8) ✅ + T089–T093 (Phase 13) ✅

---

## Phase 15: US1 Polish — Display Label "Shabbat" Instead of "ShabbatMode"

**User Story**: US1 — Basic Time Display (Priority: P1)  
**Goal**: Every user-visible text surface that currently shows "ShabbatMode" must be updated to "Shabbat". The Shabbat-active label (`Rez.Strings.ShabbatActive`) already reads "Shabbat" correctly; only the non-Shabbat/info display paths are affected.

**Root cause**:
- `resources/strings/strings.xml` `AppName` = `"ShabbatMode"` — rendered in `TimeDisplayView` Row 0 when Shabbat is not active, and in `MainView` countdown/info display via `Rez.Strings.AppName`.
- `resources/strings/strings.xml` `WelcomeTitle` = `"Welcome to ShabbatMode"` — shown on first-run overlay.
- `src/models/Configuration.mc` default `app_name` = `"ShabbatMode"` — returned by `ConfigService.getAppName()`, which is used as the app-name text component in `MainView.setupComponents()`.

**All other "Shabbat"-state labels** (`ShabbatActive`, `ShabbatModeTitle`, `ShabbatActiveLabel`) already read `"Shabbat"` — no changes needed there.

**Independent Test**: Launch the app in the Connect IQ Simulator. Verify that Row 0 of `TimeDisplayView` shows `"Shabbat"` (not `"ShabbatMode"`) at all times — both during and outside Shabbat hours.

- [x] T099 [P] [ASYNC] [US1] Update `resources/strings/strings.xml` — change `AppName` value from `"ShabbatMode"` to `"Shabbat"`; change `WelcomeTitle` value from `"Welcome to ShabbatMode"` to `"Welcome to Shabbat"`. No code changes required; the existing `Rez.Strings.AppName` reference in `TimeDisplayView` and `MainView` will automatically display the updated value.

- [x] T100 [P] [ASYNC] [US1] Update `src/models/Configuration.mc` — change the default value for `app_name` in the defaults dictionary from `"ShabbatMode"` to `"Shabbat"` so that `ConfigService.getAppName()` returns `"Shabbat"` on fresh installs and after a settings reset. This aligns the code-level default with T099's resource string change.

**Checkpoint**: After T099, build and run in the simulator — the top label on the main display reads `"Shabbat"` in all modes. `WelcomeTitle` on first-run shows `"Welcome to Shabbat"`.

---

## Phase 15 — Dependencies & Execution Order

- **T099** (string resource) — no dependencies; can run immediately  
- **T100** (Configuration.mc default) — no dependencies; fully parallel with T099 (different file)

**Recommended sequence**:
```
T099 [P]  (resources/strings/strings.xml)
T100 [P]  (src/models/Configuration.mc)
(both can run concurrently)
```

---

## Updated Dependencies (Phases 9–15)

- **Phase 9 (T071–T075)**: Complete ✅
- **Phase 10 (T076–T082)**: Complete ✅
- **Phase 11 (T083–T085)**: Complete ✅
- **Phase 12 (T086–T088)**: Complete ✅
- **Phase 13 (T089–T093)**: Complete ✅
- **Phase 14 (T094–T098)**: GPS on app load — pending
- **Phase 15 (T099–T100)**: Display label fix — no dependencies, can run alongside Phase 14

### User Story Mapping (full, updated)

- **US1 (Basic Time Display)**: T001–T020 (Phase 1–2) ✅ + **T099–T100 (Phase 15) NEW**
- **US2 (Astronomical Calculations)**: T021–T040 (Phase 3–4) ✅ + T071–T075 (Phase 9) ✅ + T094–T098 (Phase 14) new
- **US3 (Shabbat Times)**: T041–T060 (Phase 5–7) ✅ + T076–T088 (Phase 10–12) ✅
- **US4 (Battery Conservation)**: T061–T070 (Phase 8) ✅ + T089–T093 (Phase 13) ✅

---

## Phase 16: US1 Polish — Remove Seconds from All Time Displays (Always HH:MM)

**User Story**: US1 — Basic Time Display (Priority: P1)  
**Goal**: The current time shown on screen must never include seconds in any display state. Currently `TimeDisplayView` uses a Shabbat-conditional — showing `HH:MM:SS` outside Shabbat and `HH:MM` during Shabbat — and `ClockComponent` defaults `_showSeconds = true`. Both must unconditionally use `HH:MM`.

**Root cause**:
- `src/ui/TimeDisplayView.mc` lines 168–170: `isShabbat ? TimeFormatter.currentTimeHHMM() : TimeFormatter.currentTimeHHMMSS()` — seconds still appear outside Shabbat.
- `src/ui/components/ClockComponent.mc` line 37–38: `if (_showSeconds) { return TimeFormatter.currentTimeHHMMSS(); }` — `_showSeconds` defaults to `true`, so `HH:MM:SS` is the default output.
- `resources/strings/strings.xml` `TimeFormat` = `"HH:MM:SS"` — metadata string is stale.

**Note**: Phase 13 (T089–T092) previously suppressed seconds *during Shabbat*. This phase removes them *universally*, making the Shabbat-conditional in `TimeDisplayView` redundant for the time format.

**Independent Test**: Launch the app in the Connect IQ Simulator with any GPS location. At any time of day (Shabbat or not), Row 1 of `TimeDisplayView` displays `HH:MM` with no `:SS` suffix. `ClockComponent.getTimeString()` always returns a 5-character string in `HH:MM` format.

- [x] T101 [ASYNC] [US1] Update `src/ui/TimeDisplayView.mc` — in `_drawAllRows()`, replace the conditional on lines 168–170 with a single unconditional call: `var timeStr = TimeFormatter.currentTimeHHMM();`. Update the layout comment block at the top of `_drawAllRows()` (line 138) from `"Row 1 – current time HH:MM:SS"` to `"Row 1 – current time HH:MM"`.

- [x] T102 [P] [ASYNC] [US1] Update `src/ui/components/ClockComponent.mc` — in `getTimeString()`: remove the `if (_showSeconds)` branch and always `return TimeFormatter.currentTimeHHMM()`. Change `_showSeconds` default in `initialize()` from `true` to `false` so the field remains in sync if callers still use `setShowSeconds()` or `setShabbatMode()`. Update the class-level doc comment from `"Displays the current local time as 'HH:MM:SS' (or 'HH:MM' when compact)"` to `"Displays the current local time as 'HH:MM' — seconds are never shown"`.

- [x] T103 [P] [ASYNC] [US1] Update `resources/strings/strings.xml` — change `TimeFormat` value from `"HH:MM:SS"` to `"HH:MM"` to keep the metadata string consistent with the actual display format.

**Checkpoint**: Build and run in simulator — regardless of Shabbat state, the large time display in Row 1 reads `HH:MM` only. `ClockComponent.getTimeString()` returns a 5-character string at all times.

---

## Phase 16 — Dependencies & Execution Order

- **T101** (`TimeDisplayView.mc` display fix) — no dependencies, start immediately
- **T102** (`ClockComponent.mc`) — no dependencies, fully parallel with T101 (different file)
- **T103** (`strings.xml`) — no dependencies, fully parallel with T101 and T102 (different file)

**Recommended sequence**:
```
T101 [P]  (src/ui/TimeDisplayView.mc)
T102 [P]  (src/ui/components/ClockComponent.mc)
T103 [P]  (resources/strings/strings.xml)
(all three can run concurrently)
```

---

## Updated Dependencies (Phases 9–16)

- **Phase 9 (T071–T075)**: Complete ✅
- **Phase 10 (T076–T082)**: Complete ✅
- **Phase 11 (T083–T085)**: Complete ✅
- **Phase 12 (T086–T088)**: Complete ✅
- **Phase 13 (T089–T093)**: Complete ✅
- **Phase 14 (T094–T098)**: GPS on app load — pending
- **Phase 15 (T099–T100)**: Label "Shabbat" fix — pending
- **Phase 16 (T101–T103)**: Remove seconds universally — no dependencies, can run alongside Phases 14–15

### User Story Mapping (full, updated)

- **US1 (Basic Time Display)**: T001–T020 ✅ + T099–T100 (Phase 15) + **T101–T103 (Phase 16) NEW**
- **US2 (Astronomical Calculations)**: T021–T040 ✅ + T071–T075 ✅ + T094–T098 (Phase 14)
- **US3 (Shabbat Times)**: T041–T060 ✅ + T076–T088 ✅
- **US4 (Battery Conservation)**: T061–T070 ✅ + T089–T093 ✅

---

## Phase 17: New US5 — Parashat HaShavua Display

**User Story**: US5 — Parashat HaShavua Display (Priority: P3)  
**Goal**: Display the current week's Torah portion (Parashat HaShavua) on the main screen so that the user always knows which parasha is being read this Shabbat. Supports Israel vs Diaspora calendar differences (configurable via the existing `TimeConfiguration.region` setting).

**Why this feature belongs here**: The app already shows all time-critical Shabbat information. The weekly parasha is the natural next piece of Shabbat-related context a user wants at a glance without reaching for their phone.

**Design decisions**:
- **No network calls**: Parasha is calculated purely from the Hebrew date, derived offline from the Gregorian date. Aligns with Principle V (no network during Shabbat) and research §8 (no Hebrew calendar library available in CIQ).
- **Algorithm**: Maimonides' *Kiddush HaChodesh* calendar algorithm (standard in Jewish calendar software). The Hebrew year type (deficient 353/383, regular 354/384, complete 355/385 days) determines which weeks are doubled parashiyot in the Diaspora.
- **Israel vs Diaspora**: `TimeConfiguration.getRegion()` already returns `"israel"` or `"diaspora"`. When Israel diverges (typically after Pesach in non-leap years), `ParashaService` consults an offset table.
- **Data type**: Julian Day Numbers use `Lang.Long` to avoid 32-bit overflow (Hebrew epoch JD ≈ 347,996).
- **Caching**: Parasha index is recomputed at most once per Hebrew week (when `dayId / 7` changes).
- **Screen layout**: `TimeDisplayView` currently has 5 rows across 9ths of screen height. A 6th row (parasha) is added by compressing to 10ths and using `FONT_TINY`.

**54 standard parashiyot** + 7 double-parasha strings needed (Vayakhel-Pekudei, Tazria-Metzora, Achrei Mot-Kedoshim, Behar-Bechukotai, Chukat-Balak, Matot-Masei, Nitzavim-Vayelech).

**Independent Test**: Set the simulator clock to a known date (e.g., Shabbat April 18, 2026 = 20 Nisan 5786 = week of Parashat Shemini). Verify `ParashaService.getParashaName()` returns "Shemini". Cross-reference against any online Jewish calendar (hebcal.com, chabad.org, etc.).

---

- [x] T104 [SYNC] [US5] Create `src/services/HebrewCalendarService.mc` — implement the Maimonides Hebrew calendar algorithm as a static utility class. Required static methods: `julianDayFromGregorian(year as Lang.Number, month as Lang.Number, day as Lang.Number) as Lang.Long` (standard proleptic Gregorian → JD formula using Long arithmetic); `elapsedDaysHebrewYear(year as Lang.Number) as Lang.Long` (days from Hebrew epoch 1 Tishrei 1 AM using the standard molad formula: `(235*year - 234) / 19 * 29765433 / 1080 + ...` — use integer arithmetic to avoid float precision loss); `isHebrewLeapYear(year as Lang.Number) as Lang.Boolean` (true when `(7 * year + 1) % 19 < 7`); `daysInHebrewYear(year as Lang.Number) as Lang.Number` (difference between `elapsedDaysHebrewYear(year+1)` and `elapsedDaysHebrewYear(year)`); `hebrewYearType(year as Lang.Number) as Lang.Number` (1=deficient 353/383 d, 2=regular 354/384 d, 3=complete 355/385 d — derived from `daysInHebrewYear % 10`); `gregorianToHebrewYear(gregorianYear as Lang.Number, gregorianMonth as Lang.Number, gregorianDay as Lang.Number) as Lang.Number` (Hebrew year for a Gregorian date); `hebrewDayOfYear(gregorianYear as Lang.Number, gregorianMonth as Lang.Number, gregorianDay as Lang.Number) as Lang.Number` (1-based day within the Hebrew year, where day 1 = 1 Tishrei). All arithmetic uses `Lang.Long` for Julian Day values.

- [x] T105 [SYNC] [US5] Create `src/services/ParashaService.mc` — implement parasha lookup on top of `HebrewCalendarService`. Data: `_PARASHA_COUNT = 54`; static `_DIASPORA_SCHEDULE` array of `Lang.Array<Lang.Number>` — one entry per Hebrew year type (deficient regular, regular regular, complete regular, deficient leap, regular leap, complete leap = 6 types), each entry is a 55-element array mapping week-of-year (0-indexed from Rosh Hashana) to parasha index (0–53, or -1 for Yom Tov weeks, or 100+ for combined parashiyot: 100=Vayakhel-Pekudei, 101=Tazria-Metzora, 102=Achrei-Kedoshim, 103=Behar-Bechukotai, 104=Chukat-Balak, 105=Matot-Masei, 106=Nitzavim-Vayelech); `_ISRAEL_SCHEDULE` similar array with Israel adjustments. Public methods: `getParashaIndexForToday(isIsrael as Lang.Boolean) as Lang.Number`; `getParashaStringId(index as Lang.Number) as Lang.String` (returns the `Rez.Strings.Parasha_*` key for `WatchUi.loadResource()`); `getParashaName(isIsrael as Lang.Boolean) as Lang.String` (returns the display string or `"--"` on error). Cache: store `_cachedWeekId as Lang.Number` and `_cachedIndex as Lang.Number`; recompute only when `DateMath.todayDayId() / 7 != _cachedWeekId`. Add `using Toybox.WatchUi` import.

- [x] T106 [P] [ASYNC] [US5] Create `resources/strings/parasha_strings.xml` with all 54 single parasha names as string resources. IDs: `Parasha_Bereshit`, `Parasha_Noach`, `Parasha_LechLecha`, `Parasha_Vayera`, `Parasha_ChayeiSarah`, `Parasha_Toldot`, `Parasha_Vayetzei`, `Parasha_Vayishlach`, `Parasha_Vayeshev`, `Parasha_Miketz`, `Parasha_Vayigash`, `Parasha_Vayechi`, `Parasha_Shemot`, `Parasha_Vaera`, `Parasha_Bo`, `Parasha_Beshalach`, `Parasha_Yitro`, `Parasha_Mishpatim`, `Parasha_Terumah`, `Parasha_Tetzaveh`, `Parasha_KiTisa`, `Parasha_Vayakhel`, `Parasha_Pekudei`, `Parasha_Vayikra`, `Parasha_Tzav`, `Parasha_Shemini`, `Parasha_Tazria`, `Parasha_Metzora`, `Parasha_AchreiMot`, `Parasha_Kedoshim`, `Parasha_Emor`, `Parasha_Behar`, `Parasha_Bechukotai`, `Parasha_Bamidbar`, `Parasha_Nasso`, `Parasha_Behaalotecha`, `Parasha_Shelach`, `Parasha_Korach`, `Parasha_Chukat`, `Parasha_Balak`, `Parasha_Pinchas`, `Parasha_Matot`, `Parasha_Masei`, `Parasha_Devarim`, `Parasha_Vaetchanan`, `Parasha_Eikev`, `Parasha_ReEh`, `Parasha_Shoftim`, `Parasha_KiTeitzei`, `Parasha_KiTavo`, `Parasha_Nitzavim`, `Parasha_Vayelech`, `Parasha_Haazinu`, `Parasha_VeZotHaBeracha`. Combined parasha IDs: `Parasha_VayakhlelPekudei` ("Vayakhel-Pekudei"), `Parasha_TazriaMetzora` ("Tazria-Metzora"), `Parasha_AchreiKedoshim` ("Achrei-Kedoshim"), `Parasha_BeharBechukotai` ("Behar-Bechukotai"), `Parasha_ChukatBalak` ("Chukat-Balak"), `Parasha_MatotMasei` ("Matot-Masei"), `Parasha_NitzavimVayelech` ("Nitzavim-Vayelech"). Label: `ParashaLabel` ("Parasha:"). Unavailable: `ParashaUnavailable` ("--").

- [x] T107 [SYNC] [US5] Update `src/ui/TimeDisplayView.mc` — (1) add `_parashaService as ParashaService?` field; initialise with `new ParashaService()` in `initialize()` inside the try block; (2) in `_drawAllRows()`: compress the row layout from 9ths to 10ths to make room — change `row0Y = h / 10`, `row1Y = h * 3 / 10`, `row2Y = h * 5 / 10`, `row3Y = h * 68 / 100`, `row4Y = h * 80 / 100`; add `row5Y = h * 91 / 100`; (3) add Row 5 drawing block after Row 4: read `isIsrael` from `new TimeConfiguration().getRegion().equals("israel")`; call `_parashaService.getParashaName(isIsrael)`; draw in `FONT_TINY`, `COLOR_LT_GRAY` centred at `(cx, row5Y)`; (4) update layout comment block from 5 rows to 6 rows; (5) move the location/polar indicator from `h - h/14` to `row5Y` (it becomes the Row 5 content when location is unavailable — parasha is not shown when GPS is needed).

- [x] T108 [P] [ASYNC] [US5] Add string resources for the Israel/Diaspora region toggle to `resources/strings/shabbat_strings.xml`: `RegionLabel` ("Region:"), `RegionIsrael` ("Israel"), `RegionDiaspora` ("Diaspora"). These will be used by the settings screen toggle added in T109.

- [x] T109 [ASYNC] [US5] Update `src/ui/TimeSettingsView.mc` — add a fourth settings item "Region: Israel / Diaspora" below the existing tzais-method item: read `new TimeConfiguration().getRegion()`; display `(Rez.Strings.RegionLabel) + " " + (region.equals("israel") ? Rez.Strings.RegionIsrael : Rez.Strings.RegionDiaspora)`; on SELECT cycle between `"israel"` and `"diaspora"` via `config.setRegion()`; save via `ConfigService`. Depends on T108 (string resources).

- [x] T110 [P] [ASYNC] [US5] Update `specs/003-shabbat-time-display/spec.md` — add **US5: Parashat HaShavua Display (Priority: P3)**: "As a practicing Jewish user, I want to see the current week's Torah portion on the main screen so I always know which parasha is being read this Shabbat." Acceptance scenarios: (1) given GPS/date known, app shows correct parasha name on main screen; (2) given region = Israel and post-Pesach week where Israel and Diaspora differ, correct Israel parasha is shown; (3) given parasha calculation unavailable, "--" is shown gracefully. Add **FR-015**: "System MUST display the current week's Parashat HaShavua on the main screen, computed offline from the Hebrew date." Add **FR-016**: "System MUST support Israel vs Diaspora parasha calendar differences, selectable via the region setting."

- [x] T111 [P] [ASYNC] [US5] Update `specs/003-shabbat-time-display/research.md` — add **§10: Hebrew Calendar & Parasha Algorithm**: document the Maimonides molad-based calendar algorithm used by `HebrewCalendarService`; document the 6 Hebrew year types (deficient/regular/complete × regular/leap) and how they determine which parasha weeks are doubled in the Diaspora; list the 7 possible double-parasha combinations and which year types trigger each; document Israel vs Diaspora divergence (typically 1–4 weeks apart after Pesach in certain years); add cross-reference table: "KosherJava `JewishCalendar.getParashahIndex()`" → `ParashaService.getParashaIndexForToday()`.

**Checkpoint**: Set simulator date to Shabbat April 18, 2026 (20 Nisan 5786 = Shemini week). Verify Row 5 of `TimeDisplayView` shows "Parasha: Shemini". Toggle region to Israel; verify same result (this week they match). Set date to April 25, 2026 (Tazria-Metzora in Diaspora, Tazria in Israel); verify correct split.

---

## Phase 17 — Dependencies & Execution Order

- **T104** (`HebrewCalendarService`) — no dependencies, start immediately; foundation for T105
- **T105** (`ParashaService`) — depends on T104 complete (uses `HebrewCalendarService` and `DateMath`)
- **T106** (parasha string resources) — no dependencies, parallel with T104/T105
- **T107** (`TimeDisplayView` UI) — depends on T105 complete (calls `ParashaService`) + T106 complete (uses `Rez.Strings.Parasha_*`)
- **T108** (region strings) — no dependencies, parallel
- **T109** (`TimeSettingsView` toggle) — depends on T108 (uses `Rez.Strings.RegionLabel`)
- **T110** (spec.md) — no dependencies, parallel
- **T111** (research.md) — no dependencies, parallel

**Recommended sequence**:
```
T104 → T105 → T107 (sequential core chain)
T106 [P]           (resources/strings/parasha_strings.xml, parallel with T104)
T108 [P]           (shabbat_strings.xml, parallel)
  → T109           (TimeSettingsView, after T108)
T110 [P]           (spec.md, parallel)
T111 [P]           (research.md, parallel)
```

---

## Updated Dependencies (Phases 9–17)

- **Phase 9–13**: Complete ✅
- **Phase 14 (T094–T098)**: GPS on app load — pending
- **Phase 15 (T099–T100)**: Label "Shabbat" fix — pending
- **Phase 16 (T101–T103)**: Remove seconds — pending
- **Phase 17 (T104–T111)**: Parashat HaShavua display — new, no dependencies on Phases 14–16

### User Story Mapping (final)

- **US1 (Basic Time Display)**: T001–T020 ✅ + T099–T100 + T101–T103
- **US2 (Astronomical Calculations)**: T021–T040 ✅ + T071–T075 ✅ + T094–T098
- **US3 (Shabbat Times)**: T041–T060 ✅ + T076–T088 ✅
- **US4 (Battery Conservation)**: T061–T070 ✅ + T089–T093 ✅
- **US5 (Parashat HaShavua)**: T104–T111 ✅ + **T112–T120 NEW (Phase 18 validation)**

---

## Phase 18: US5 Validation — Parashat HaShavua Display

**User Story**: US5 — Parashat HaShavua Display (Priority: P3)  
**Goal**: Verify the fully implemented parasha pipeline (`HebrewCalendarService` → `ParashaService` → `TimeDisplayView` Row 5) produces correct results for a representative set of dates, including Israel/Diaspora divergence weeks, special Shabbatot, Yom Tov weeks, and leap years.

**Constitutional alignment**: Principle V (Simplicity and Reliability) — no network; offline Hebrew calendar math must be demonstrably correct before shipping. FR-015 and FR-016 require verified accuracy.

**Independent Test**: Set the Connect IQ Simulator clock to Saturday April 18, 2026. Open `TimeDisplayView`. Row 5 must display "Parasha: Shemini" in `COLOR_LT_GRAY`. Toggle region to Israel; Row 5 must still display "Shemini" (schedules match this week).

---

### Phase 18a: Hebrew Calendar Foundation Validation

- [x] T112 [SYNC] [US5] Validate `HebrewCalendarService` date conversion accuracy in `src/services/HebrewCalendarService.mc` — in the Connect IQ Simulator, add a temporary `System.println` in `TimeDisplayView.onShow()` that prints `HebrewCalendarService.todayHebrewYear()`, `todayHebrewDayOfYear()`, `todayHebrewMonth()`, `todayHebrewDay()` with simulator clock set to: (a) April 18, 2026 → expect year=5786, month=8 (Nissan), day=20; (b) Oct 3, 2024 → expect year=5785, month=1 (Tishrei), day=1 (Rosh Hashana); (c) Sept 26, 2025 → expect year=5786, month=1, day=3 (3 Tishrei 5786). Cross-reference: chabad.org Hebrew date converter.

- [x] T113 [SYNC] [US5] Validate `HebrewCalendarService.roshHashanaDayOfWeek()` for `src/services/HebrewCalendarService.mc` — print `roshHashanaDayOfWeek(5786)` (Rosh Hashana 5786 = Sept 23, 2025, a Tuesday → expect 3); print `roshHashanaDayOfWeek(5785)` (Rosh Hashana 5785 = Oct 3, 2024, a Thursday → expect 5); print `roshHashanaDayOfWeek(5784)` (Rosh Hashana 5784 = Sept 16, 2023, a Saturday → expect 7). These values drive the `_parshaYearType()` switch in `ParashaService`.

---

### Phase 18b: Parasha Calculation Correctness

- [x] T114 [SYNC] [US5] Validate standard parasha — set simulator to Saturday **April 18, 2026** (week of Parashat Shemini, 20 Nisan 5786): verify `ParashaService.getParashaName(false)` returns `"Shemini"` (Diaspora) and `getParashaName(true)` also returns `"Shemini"` (Israel matches this week — 4th Shabbat of Nissan). Reference: chabad.org/parasha for April 18, 2026.

- [x] T115 [SYNC] [US5] Validate Israel/Diaspora divergence — set simulator to Saturday **April 25, 2026** (2 Iyar 5786; Diaspora reads Tazria-Metzora, Israel reads Tazria only — post-Pesach split week): verify `getParashaName(false)` returns `"Tazria-Metzora"` (combined, index 101) and `getParashaName(true)` returns `"Tazria"` (index 26). Reference: hebcal.com parasha for April 25, 2026.

- [x] T116 [SYNC] [US5] Validate Yom Tov week graceful fallback — set simulator to Saturday **April 11, 2026** (13 Nisan 5786, the Shabbat before Pesach begins; no regular parasha reading): verify `ParashaService.getParashaName(false)` returns `"--"` (parasha index -1) without throwing an exception. Confirm no crash logged in simulator output.

- [x] T117 [P] [SYNC] [US5] Validate leap-year separate parasha — set simulator to Saturday **April 19, 2025** (21 Nisan 5785, a Hebrew leap year; Diaspora reads Tazria separately, not combined): verify `getParashaName(false)` returns `"Tazria"` (index 26, not the combined 101). Reference: hebcal.com April 19, 2025 (leap year 5785 — Tazria and Metzora are read on separate weeks in a leap year).

---

### Phase 18c: Special Shabbatot Detection

- [x] T118 [SYNC] [US5] Validate Shabbat Zachor (Arba Parashiyot) — set simulator to Saturday **March 7, 2026** (7 Adar 5786, Shabbat immediately before Purim; Shabbat Zachor): verify `ParashaService.getSpecialShabbosIndex(false)` returns `201` (Zachor), `getParashaName(false)` contains `"Zachor"` in the returned string (special name appended in parentheses), and `TimeDisplayView` Row 5 renders in `Graphics.COLOR_YELLOW` instead of `COLOR_LT_GRAY`. Reference: hebcal.com for March 7, 2026.

- [x] T119 [SYNC] [US5] Validate Shabbat Shira — set simulator to Saturday **February 7, 2026** (9 Shevat 5786, week of Beshalach): verify `getSpecialShabbosIndex(false)` returns `208` (Shira) and `getParashaName(false)` returns a string containing both "Beshalach" and "Shira". Reference: `_specialShabbosForShabbat()` in `src/services/ParashaService.mc` — Shabbat Shira fires whenever `parashaIndex == 15` (Beshalach).

---

### Phase 18d: UI Rendering Verification

- [x] T120 [P] [ASYNC] [US5] Validate Row 5 layout in `src/ui/TimeDisplayView.mc` — in the Connect IQ Simulator at 240×240 resolution, verify: (a) Row 5 `y` position = `h * 91 / 100` = 218 px (does not overlap Row 4 at `h * 80 / 100` = 192 px); (b) `FONT_TINY` text fits within the screen width for the longest expected label, e.g. `"Parasha: Nitzavim-Vayelech"` (25 chars); (c) when Row 0 shows a location error, Row 5 is still drawn independently (parasha requires no GPS). If text is clipped at 240 px width, document the finding in `specs/003-shabbat-time-display/validation/parasha-layout-notes.md`.

---

## Phase 18 — Dependencies & Execution Order

- **T112** (Hebrew calendar date conversion) — no dependencies; start immediately; foundation for T113–T119
- **T113** (Rosh Hashana DOW) — depends on T112 complete (same debugging session); run sequentially after T112
- **T114** (standard parasha Apr 18) — depends on T112 + T113 complete (validates calendar → parasha pipeline)
- **T115** (Israel/Diaspora divergence) — depends on T114 (same pipeline, adjacent week)
- **T116** (Yom Tov fallback) — depends on T114 (tests same service)
- **T117** [P] (leap year) — depends on T114; can run in parallel with T115 and T116 (different date, same service)
- **T118** (Shabbat Zachor) — depends on T114 (tests special Shabbat path); parallel with T117
- **T119** (Shabbat Shira) — depends on T114; parallel with T118 (different special Shabbat)
- **T120** [P] (UI layout) — no code dependencies; can run in parallel with any Phase 18 task (different concern)

**Recommended sequence**:

```
T112 → T113 → T114 (sequential calendar validation chain)
  → T115 [P]  (Diaspora/Israel split, after T114)
  → T116 [P]  (Yom Tov, after T114)
  → T117 [P]  (leap year, after T114)
  → T118 [P]  (Shabbat Zachor, after T114)
  → T119 [P]  (Shabbat Shira, after T114)
T120 [P]      (UI layout, parallel throughout)
```

**Checkpoint (Phase 18 complete)**: All nine test dates produce the expected output. Israel/Diaspora split for April 25, 2026 is confirmed. Special Shabbatot render in yellow. No crashes on Yom Tov or error inputs.

---

## Updated Dependencies (Phases 9–18)

- **Phase 9–13**: Complete ✅
- **Phase 14 (T094–T098)**: GPS on app load — complete ✅
- **Phase 15 (T099–T100)**: Label "Shabbat" fix — complete ✅
- **Phase 16 (T101–T103)**: Remove seconds — complete ✅
- **Phase 17 (T104–T111)**: Parashat HaShavua display — complete ✅
- **Phase 18 (T112–T120)**: Parasha validation — **NEW**

### User Story Mapping (final, updated)

- **US1 (Basic Time Display)**: T001–T020 ✅ + T099–T100 ✅ + T101–T103 ✅
- **US2 (Astronomical Calculations)**: T021–T040 ✅ + T071–T075 ✅ + T094–T098 ✅
- **US3 (Shabbat Times)**: T041–T060 ✅ + T076–T088 ✅
- **US4 (Battery Conservation)**: T061–T070 ✅ + T089–T093 ✅
- **US5 (Parashat HaShavua)**: T104–T111 ✅ + **T112–T120 (Phase 18)**
