# Implementation Plan: Parashat HaShavua Display (US5)

**Branch**: `feature/003-parasha-hashavua-us5` | **Date**: 2026-04-23 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/003-shabbat-time-display/spec.md` — User Story 5 (FR-015, FR-016)

## Summary

Add the current week's Parashat HaShavua (weekly Torah portion) to Row 5 of the main `TimeDisplayView`, computed entirely offline from the Hebrew calendar date. The implementation uses the Maimonides / Dershowitz-Reingold algorithm for Gregorian → Hebrew date conversion, and the KosherJava 17-type parasha schedule table for lookup. Supports Israel vs. Diaspora calendar differences via the existing `TimeConfiguration.region` setting. Special Shabbatot (Arba Parashiyot, Shabbat Shira, etc.) are highlighted in yellow.

**Status**: Implementation complete (Phase 17). Offline validation complete (Phase 18 — all 34 checks pass via `verify-parasha.py`). Simulator validation pending.

## Technical Context

**Language/Version**: Monkey C (Connect IQ SDK 4.0+)  
**Primary Dependencies**: `Toybox.WatchUi`, `Toybox.Time.Gregorian`, `Toybox.Lang`  
**Storage**: No persistent storage required — parasha is computed on-device from the system clock  
**Testing**: Connect IQ Simulator (manual) + Python offline validator (`specs/003-shabbat-time-display/validation/verify-parasha.py`)  
**Target Platform**: Garmin Connect IQ devices (CIQ 3.0+, always-on display)  
**Project Type**: Watch face / watch app (Garmin CIQ)  
**Performance Goals**: Parasha lookup < 1ms (cached per Hebrew week); Hebrew calendar math runs once at cache miss  
**Constraints**: No network calls; all computation from device clock; `Lang.Long` required for Julian Day arithmetic to prevent 32-bit overflow  
**Scale/Scope**: Single-watch display; 54 standard + 7 combined + 9 special Shabbat parashiyot; 17 Hebrew year-type schedule rows (KosherJava port)

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I — Shabbat Compliance First | ✅ PASS | Parasha is display-only, calendar-only; zero sensor activation |
| II — Always-On Display | ✅ PASS | Row 5 shown passively; no additional redraw cycles beyond existing timer |
| III — Minimal Sensor Footprint | ✅ PASS | No GPS, no network, no new sensors for parasha lookup |
| IV — Zero Interaction During Shabbat | ✅ PASS | Parasha updates weekly at cache miss; no user action required |
| V — Simplicity and Reliability | ✅ PASS | Offline algorithm; falls back to "--" gracefully on any error; no added state |

**No violations.** Feature justified under Principle I (religious observance context) and Principle V (reliable offline calendar math).

## Project Structure

### Documentation (this feature)

```text
specs/003-shabbat-time-display/
├── plan.md              # This file
├── research.md          # KosherJava algorithm mapping, §8 and §10
├── data-model.md        # Entities including HebrewCalendarService, ParashaService
├── quickstart.md        # Developer setup and simulator testing guide
├── tasks.md             # Phases 9–18 (T071–T120)
└── validation/
    └── verify-parasha.py  # Offline Python validator — T112–T120
```

### Source Code (repository root)

```text
src/
├── services/
│   ├── HebrewCalendarService.mc   # Gregorian → Hebrew date (Maimonides algorithm)
│   ├── ParashaService.mc          # Hebrew date → Parasha index (KosherJava 17-type table)
│   └── ...
├── ui/
│   └── TimeDisplayView.mc         # Row 5: _drawParasha() — Parasha: <name>
└── ...

resources/
└── strings/
    └── parasha_strings.xml        # 54 single + 7 combined + 9 special Shabbat strings
                                   # + ParashaLabel, ParashaUnavailable
```

**Structure Decision**: Single-project Garmin CIQ structure. Parasha logic is a service layer (`src/services/`) consumed by the UI layer (`src/ui/`), consistent with existing `AstronomicalService` + `ShabbatTimeService` patterns.

## Phase 0: Research

All unknowns resolved. See [`research.md`](research.md) §8 (No Hebrew calendar library in CIQ) and §10 (Hebrew Calendar & Parasha Algorithm).

**Key decisions:**
- **Algorithm**: Maimonides molad-based calendar (Dershowitz-Reingold) — same as KosherJava. Integer arithmetic throughout; `Lang.Long` for JDN values.
- **Schedule table**: KosherJava 17-type `parshalist` ported verbatim to Monkey C. 17 rows cover all combinations of leap/non-leap × year length (deficient/regular/complete) × Israel/Diaspora.
- **Epoch**: Hebrew epoch JDN = 347,997 (not 347,996 — matching KosherJava `JEWISH_EPOCH`). `MOLAD_TOHU` = 31,524 chalakim (1d 5h 204p from Sunday, matching `CHALAKIM_MOLAD_TOHU`).
- **Israel/Diaspora**: Consult separate year-type table rows (12–16) when `TimeConfiguration.getRegion().equals("israel")`.
- **Caching**: Week ID (`DateMath.todayDayId() / 7`) used as cache key; recompute at week boundary only.
- **Offline validation**: Python mirror of both `HebrewCalendarService` and `ParashaService` algorithms confirms all test cases before simulator testing.

See [`validation/verify-parasha.py`](validation/verify-parasha.py) for all 34 test cases (T112–T120) — all pass.

## Phase 1: Design & Implementation

### Data Model

See [`data-model.md`](data-model.md) for full entity definitions. Key additions for US5:

| Entity | Location | Role |
|--------|----------|------|
| `HebrewCalendarService` | `src/services/HebrewCalendarService.mc` | Static utility: Gregorian → JDN → Hebrew year/month/day. All methods static; `Lang.Long` arithmetic throughout. |
| `ParashaService` | `src/services/ParashaService.mc` | Instance: Hebrew date → parasha index → display string. Caches by week ID + Israel flag. 17-row KosherJava schedule table. |
| `TimeConfiguration.region` | `src/models/TimeConfiguration.mc` | Existing field; `"israel"` / `"diaspora"` toggle. |

### Interface Contracts

No external interfaces. This is a watch face; all data flows from device clock → service layer → display.

### Key Design Choices

**Row layout compression (T107)**:  
Previous layout used 9ths; 6 rows now use 10ths:
```
Row 0: h/10       (mode label / GPS status)
Row 1: h*3/10     (current time HH:MM — large)
Row 2: h*5/10     (sunrise ↑ / sunset ↓)
Row 3: h*68/100   (candle lighting)
Row 4: h*80/100   (end of Shabbat / Havdalah)
Row 5: h*91/100   (Parashat HaShavua — FONT_TINY)
```
At 240×240: Row 4 = 192 px, Row 5 = 218 px, gap = 26 px (FONT_TINY ≈ 12–14 px tall — no overlap).

**Special Shabbat highlighting (T107/ParashaService)**:  
When `getSpecialShabbosIndex()` returns 200–208, Row 5 renders in `COLOR_YELLOW`; otherwise `COLOR_LT_GRAY`. Special name appended in parentheses, e.g. `"Tetzaveh (Zachor)"`.

**Error handling**:  
Any exception in `_drawParasha()` leaves Row 5 blank — no crash, no "--" cluttering the display when truly unavailable.

## Triage Framework: [SYNC] vs [ASYNC] Classification

| Task Category | [SYNC] Tasks | [ASYNC] Tasks | Rationale |
|---------------|-------------|--------------|-----------|
| Business Logic | 6 (T104–T107, T112–T119) | 0 | Calendar math and halachic correctness require human review |
| Data Operations | 0 | 0 | No persistent storage |
| UI Components | 1 (T107) | 1 (T120) | Layout math is deterministic; rendering needs human review |
| String Resources | 0 | 3 (T106, T108, T110) | Mechanical XML generation |
| Documentation | 0 | 3 (T109, T111) | Docs/spec updates are non-critical |

### Triage Audit Trail

| Task | Classification | Primary Criteria | Risk Level | Rationale |
|------|----------------|------------------|------------|-----------|
| T104 — HebrewCalendarService | SYNC | Complex algorithm, halachic correctness | High | Molad arithmetic, dehiyyot postponement rules — off-by-one in epoch = wrong year for all users |
| T105 — ParashaService | SYNC | Algorithm, 17-type schedule port | High | Incorrect year-type mapping = wrong parasha every week |
| T106 — parasha_strings.xml | ASYNC | Mechanical string resource creation | Low | 54+7+9 string IDs, no logic |
| T107 — TimeDisplayView Row 5 | SYNC | UI layout, service wiring | Medium | Row layout compression affects all 5 existing rows |
| T108 — Region strings | ASYNC | Mechanical string resource | Low | 3 string IDs |
| T109 — TimeSettingsView toggle | ASYNC | Standard CIQ settings pattern | Low | Follows existing tzais-method toggle pattern exactly |
| T110 — spec.md update | ASYNC | Documentation | Low | No code impact |
| T111 — research.md update | ASYNC | Documentation | Low | No code impact |
| T112–T119 — Validation | SYNC | Halachic correctness verification | High | Must confirm correct parasha against authoritative sources |
| T120 — UI layout validation | ASYNC | Mechanical pixel math | Low | Row positions verified analytically |

## Complexity Tracking

No constitution violations requiring justification.

## Implementation Status

### Completed

| Phase | Tasks | Status |
|-------|-------|--------|
| Phase 17 — Core Implementation | T104–T111 | ✅ Complete |
| Phase 18a — Hebrew Calendar Validation | T112–T113 | ✅ Validated offline (verify-parasha.py) |
| Phase 18b — Parasha Calculation Correctness | T114–T117 | ✅ Validated offline |
| Phase 18c — Special Shabbatot Detection | T118–T119 | ✅ Validated offline |
| Phase 18d — UI Layout Verification | T120 | ✅ Validated offline (row math) |

**Bug fixed in this branch**: `HebrewCalendarService.mc`  
- `HEBREW_EPOCH_JD`: 347,996 → 347,997 (correct KosherJava epoch)  
- `MOLAD_TOHU`: 57,444 → 31,524 (correct KosherJava `CHALAKIM_MOLAD_TOHU`)  
- `julianDayFromGregorian()`: replaced non-standard formula with Calendar FAQ standard algorithm

### Remaining

| Task | Description | Blocker? |
|------|-------------|----------|
| Connect IQ Simulator tests (T112–T119) | Visual confirmation of Row 5 in simulator | No (offline validation passes; simulator is belt-and-suspenders) |

## Validation Evidence

All 34 offline test cases from `verify-parasha.py` pass:

```
T112 — Hebrew calendar date conversion (3 dates × 3 fields = 9 checks) ✅
T113 — Rosh Hashana day-of-week for 5784, 5785, 5786               ✅
T114 — Shemini (Apr 11 2026, both Israel and Diaspora)             ✅
        + Tazria-Metzora (Apr 18 2026, Diaspora)                   ✅
T115 — Israel/Diaspora split: Nasso vs Beha'alotecha (May 30 2026) ✅
T116 — Yom Tov fallback: "--" for Shabbat Chol HaMoed Pesach      ✅
T117 — Leap year: Tazria and Metzora separate in 5784              ✅
T118 — Shabbat Zachor: sidx=201, regular=Tetzaveh (Feb 28 2026)   ✅
T119 — Shabbat Shira: sidx=208, parasha=Beshalach (Jan 31 2026)   ✅
T120 — Row layout math: Row4=192px, Row5=218px, gap=26px           ✅
```

Run: `python3 specs/003-shabbat-time-display/validation/verify-parasha.py`
