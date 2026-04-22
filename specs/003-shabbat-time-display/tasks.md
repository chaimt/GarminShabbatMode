# Tasks: Shabbat Time Display — KosherJava Algorithm Port

**Input**: Design documents from `/specs/003-shabbat-time-display/`  
**Algorithm Reference**: https://kosherjava.com/zmanim-project/  
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md (KosherJava mapping), context.md

**Dependencies**: Base application framework complete. Phases 1–8 (T001–T070) complete.  
**This tasks.md**: Covers the KosherJava port enhancement — generalizing the solar calculator and adding degree-based zmanim.

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

- [ ] TDD-001 [SYNC] Verify `SunCalculator.calculateSunsetAtZenithUTC(69.65, 18.96, n, 90.8333)` returns `null` for Tromsø, Norway (69.65°N) on 2025-06-21 (midnight sun) — polar region must not produce a sunset time. Replaces the old `calculateSunsetUTC` polar check.

- [ ] TDD-002 [SYNC] Verify `SunCalculator.calculateSunriseAtZenithUTC(69.65, 18.96, n, 90.8333)` returns `null` for Tromsø on 2025-12-21 (polar night) — no sunrise during Arctic winter.

- [ ] TDD-003 [SYNC] Verify `SunCalculator.calculateTzaisLocalSeconds(69.65, 18.96, n, utcOffset, "degrees_8_5", 42)` returns `-1` (unavailable) when the degree-based calculation returns null for a polar location — graceful degradation, no crash.

### Happy Path — Standard Sunset Regression

- [ ] TDD-004 [SYNC] Verify `SunCalculator.calculateSunsetAtZenithUTC(40.096, -74.222, n, 90.8333)` for Lakewood NJ on 2026-04-22 produces a UTC result within ±60 seconds of the value previously returned by `SunCalculator.calculateSunsetUTC(40.096, -74.222, n)` — confirms the refactoring in T073 is a pure regression with no behaviour change.

- [ ] TDD-005 [SYNC] Verify `SunCalculator.calculateSunriseAtZenithUTC(40.096, -74.222, n, 90.8333)` for Lakewood NJ on 2026-04-22 produces a UTC result within ±60 seconds of the sunrise previously calculated in `AstronomicalService._calculateSunriseUTC()` — confirms T074/T075 refactor is safe.

### Happy Path — Degree-Based Tzais (KosherJava Equivalents)

- [ ] TDD-006 [SYNC] [US3] Verify `SunCalculator.calculateSunsetAtZenithUTC(40.096, -74.222, n, 98.5)` for Lakewood NJ on 2026-04-22 produces a UTC time approximately 40–44 minutes after standard sunset (zenith 90.8333°) — matches expected output of KosherJava `ComplexZmanimCalendar.getTzaisGeonim8Point5Degrees()` within ±2 minutes. Reference: check https://kosherjava.com/zmanim-project/zmanim-calendar/ for the same date and location.

- [ ] TDD-007 [SYNC] [US3] Verify `SunCalculator.calculateSunsetAtZenithUTC(31.78, 35.22, n, 98.5)` for Jerusalem on 2026-04-22 produces a UTC time approximately 35–38 minutes after standard sunset — KosherJava `getTzaisGeonim8Point5Degrees()` for Jerusalem. Validates that the zenith calculation is location-dependent (differs from New York result).

- [ ] TDD-008 [SYNC] [US3] Verify `SunCalculator.calculateSunsetAtZenithUTC(51.51, -0.12, n, 97.083)` for London on 2026-04-22 produces a UTC time approximately 27–31 minutes after standard sunset — matches KosherJava `getTzaisGeonim7Point083Degrees()` within ±2 minutes.

### Edge Cases

- [ ] TDD-009 [P] [SYNC] [US3] Verify that when `TimeConfiguration.getTzaisMethod()` returns `"degrees_8_5"`, `ShabbatTimeService.getShabbatTimes()` returns a `ShabbatTimes` object whose `getShabbatEndLocalSeconds()` matches the result of `SunCalculator.calculateTzaisLocalSeconds(..., "degrees_8_5", ...)` — i.e., the service correctly delegates to the degree-based path.

- [ ] TDD-010 [P] [SYNC] [US3] Verify that `ShabbatWindowService.isShabbat()` boundary on Saturday night matches `ShabbatTimeService.getShabbatTimes().getShabbatEndLocalSeconds()` — both must use the same tzais computation so conservation mode ends exactly when the display shows Shabbat has ended. Test by overriding simulator clock to 1 second before and 1 second after the computed tzais time.

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
