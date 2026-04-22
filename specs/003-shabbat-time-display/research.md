# Research: Shabbat Time Display

**Feature**: `003-shabbat-time-display`  
**Date**: 2026-04-22  
**Status**: Complete

---

## Unknowns Resolved

### 1. Astronomical Calculation Library Selection

**Question**: Can the KosherJava Zmanim library (https://kosherjava.com/zmanim-project/) be used directly in the Garmin Connect IQ environment?

**Decision**: No — KosherJava is a Java library and cannot run in the Garmin Connect IQ (Monkey C) runtime. The algorithms must be ported.

**Rationale**: Garmin watches run Monkey C, a proprietary language compiled to a CIQ bytecode VM. There is no JVM, no JNI, and no dynamic linking. External `.jar` files are not usable. However, KosherJava documents its algorithmic source: it uses the **NOAA Simplified Solar Position Algorithm** for sunrise and sunset, and **degree-based or fixed-minute offsets** for halachic times derived from those positions. All of these are pure mathematical formulas that can be ported to Monkey C's `Toybox.Math` API.

**Alternatives Considered**:
- Use an HTTP REST API for zmanim lookups — rejected (violates Principle V: no network calls during Shabbat; watch must work offline)
- Use SunTimesCalculator (US Naval Observatory algorithm, the older KosherJava calculator) — rejected; NOAA algorithm is more accurate and is KosherJava's default since v1.3
- Port KosherJava's full `ComplexZmanimCalendar` class set — rejected; only a tiny subset of the 157 zmanim are needed (sunrise, sunset, candle lighting, tzais)

---

### 2. Which Solar Algorithm to Use

**Question**: The NOAA simplified algorithm vs. the full NOAA analytical algorithm vs. the SPA (Solar Position Algorithm, NREL 2003) — which is appropriate for ±2 minute accuracy on a Garmin watch?

**Decision**: NOAA Simplified Solar Position Algorithm (Jean Meeus, "Astronomical Algorithms," Chapter 25).

**Rationale**:
- The simplified NOAA algorithm produces sunrise/sunset times accurate to **±1–2 minutes** at typical latitudes (23°N–60°N) — exactly matching the ±2 minute requirement in SC-002.
- KosherJava uses this same algorithm as its `NOAACalculator` (the default since v1.3). The KosherJava comment thread at kosherjava.com/zmanim-project confirms this matches outputs from `timeanddate.com`.
- The zenith used for standard sunrise/sunset is **90.8333°** (= 90° + 50' combined solar radius (16') + atmospheric refraction (34')), matching KosherJava's `GEOMETRIC_ZENITH + 0.8333`.
- The full NREL SPA algorithm is more accurate (±0.0003°) but requires 100+ intermediate variables — unnecessary for this use case and risky on Garmin's 32-bit floats.
- The US Naval Observatory algorithm (`SunTimesCalculator` in KosherJava) is simpler but less accurate; KosherJava's own documentation recommends switching to the NOAA calculator.

**Implementation**: `src/services/SunCalculator.mc` — NOAA simplified algorithm ported to Monkey C. Verified against KosherJava `ZmanimCalendar` reference outputs within ±1 minute for test locations (New York, Jerusalem, London) across all seasons.

---

### 3. Candle Lighting Time Calculation

**Question**: How does KosherJava calculate candle lighting time? Is the offset relative to sunset or some other reference?

**Decision**: Candle lighting = **local sunset − `candleLightingOffset` minutes** (configurable, default 18 minutes).

**Rationale**: KosherJava's `ZmanimCalendar.getCandleLighting()` returns `getSeaLevelSunset() - candleLightingOffset`. The default is 18 minutes. Many communities use 18–20 minutes; some (e.g., Jerusalem) use 40 minutes. Our `TimeConfiguration.getCandleLightingOffset()` provides this as a configurable value, matching KosherJava's API design exactly.

**Alternatives Considered**:
- Calculate candle lighting at a specific solar zenith angle — rejected; no community uses this; fixed-minute offset is the universally accepted standard.

---

### 4. End-of-Shabbat (Tzais) Calculation Method

**Question**: How does KosherJava calculate tzais (nightfall / end of Shabbat)? The library lists 30+ tzais opinions (Tzais Geonim 3.676° through Tzais 120 minutes). Which should we use?

**Decision**: **Fixed-minute offset** (configurable, default 42 minutes after sunset) with an optional **8.5° below-horizon** degree-based calculation available as a user preference.

**Rationale**:
- **Fixed minutes** — 25 min (very lenient, Geonim), 42 min (Rabbeinu Tam, widely used in Ashkenaz), 50 min (Rav Moshe Feinstein for New York), 72 min (Rabbeinu Tam strict) — are the standard approach for most observant users and match what the majority of synagogue calendars publish.
- **Degree-based (8.5° below horizon / Tzais Geonim 8.5°)** — This is the KosherJava `getTzaisGeonim8Point5Degrees()` method, which calculates when the sun is 8.5° below the horizon. Zenith = 90 + 8.5 = 98.5°. This can be computed using a generalised version of the NOAA algorithm (replace the -0.8333° refraction zenith with the desired angle below horizon). This corresponds to approximately 35–42 minutes after sunset depending on latitude and season.
- **Complexity vs. accuracy trade-off**: Degree-based tzais provides season/location-adjusted nightfall but requires exposing solar zenith configuration to users, which increases UI complexity. Fixed-minute offsets are simpler, more widely understood by the target audience, and still accurate enough for practical observance.
- **Constitution alignment**: Principle V (Simplicity) favours fixed minutes as the default. Users who prefer degree-based can select it via `TimeSettingsView`.

**Implementation Notes**:
- `TimeConfiguration.getShabbatEndOffset()` stores the fixed-minute offset (default 42 minutes).
- **Degree-based tzais is now implemented** in `SunCalculator.calculateTzaisLocalSeconds()` (Phase 10, T077). The method accepts a `method` parameter: `"fixed_minutes"`, `"degrees_8_5"` (zenith 98.5°), or `"degrees_7_083"` (zenith 97.083°).
- The formula: for zenith `z`, the hour angle `cosH = (sin(90° - z) - sin(lat)·sin(delta)) / (cos(lat)·cos(delta))`. For z = 98.5° this gives `sin(-8.5°)` — exactly 8.5° below horizon.
- `TimeConfiguration.getTzaisMethod()` returns the selected method; `TimeSettingsView` exposes a 3-way cycle selector.
- `ShabbatWindowService` uses the same `calculateTzaisLocalSeconds()` call to ensure battery conservation boundaries match displayed times exactly.

**Degree-Based Tzais — Minutes After Sunset by Latitude (approximate)**:

| Latitude | 8.5° (spring) | 8.5° (summer) | 7.083° (spring) |
|----------|--------------|--------------|-----------------|
| 32°N (Jerusalem) | ~35 min | ~38 min | ~29 min |
| 40°N (New York)  | ~42 min | ~48 min | ~35 min |
| 51°N (London)    | ~48 min | ~60+ min| ~40 min |
| 32°S (Melbourne) | ~35 min | ~30 min | ~29 min |

---

### 5. Floating-Point Precision on Garmin Devices

**Question**: Garmin CIQ uses 32-bit IEEE 754 floats by default on most devices. Does this affect ±2 minute accuracy?

**Decision**: 32-bit floats are sufficient; no special precision handling needed.

**Rationale**:
- The NOAA simplified algorithm uses intermediate values with ~6 significant digits. 32-bit floats provide ~7 significant decimal digits of precision.
- The dominant source of error is atmospheric refraction variability (up to ±2 min) rather than floating-point rounding.
- KosherJava itself uses Java `double` (64-bit) for cosmetic precision, but KosherJava's own documentation states that "zmanim can be off by up to 2 minutes based on atmospheric conditions." This means the ±2 min spec requirement is fundamentally limited by physics, not by float precision.
- Testing on the Connect IQ Simulator confirmed that results for New York (40.096°N, -74.222°W) match KosherJava outputs within ±1 minute across all four calendar seasons.

---

### 6. UTC Offset and Timezone Handling

**Question**: How does the Monkey C `Toybox.Time` API handle timezones? Do we need to implement our own DST table?

**Decision**: Use `Toybox.System.getDeviceSettings().timeZoneOffset` for the current UTC offset in minutes. No custom DST table needed.

**Rationale**:
- `System.getDeviceSettings().timeZoneOffset` returns the current UTC offset in seconds (negative west of UTC), automatically adjusted for DST as configured on the device.
- This is the same offset used to convert the NOAA UTC output to local wall-clock time.
- For travelers crossing timezone boundaries, the device offset updates automatically via GPS sync or manual adjustment by the user. Our `TimezoneService` reads this on each calculation cycle.
- KosherJava uses Java `TimeZone` objects for the same purpose. The Monkey C equivalent is `timeZoneOffset`.

**Limitation**: Unlike Java's `TimeZone.getTimeZone("America/New_York")`, the Garmin API does not expose IANA timezone identifiers. This means historical DST boundary lookups are unavailable. In practice this is acceptable because the device always reflects the current correct offset.

---

### 7. GPS Usage and Battery Efficiency

**Question**: How often should the app poll GPS to maintain calculation accuracy while minimising battery drain?

**Decision**: Poll every **5 minutes** during normal operation; extend to every **30 minutes** during Shabbat conservation mode.

**Rationale**:
- Astronomical calculations (sunrise/sunset) change by only ~1 minute per day at typical latitudes. Once a GPS fix is obtained for the current day, the cached location is valid for the entire day.
- 5-minute polling during normal operation ensures the location is fresh for the first calculation but wastes battery during Shabbat when the user is not moving.
- 30-minute polling during Shabbat satisfies SC-006 (GPS polling ≤ once per 30 minutes during conservation mode) and reduces GPS-related battery draw by ~6×.
- `LocationCache` persists the last known location to `Application.Storage`, allowing the app to survive watch restarts without requiring an immediate GPS fix.
- This approach mirrors the battery optimisation pattern used in KosherJava-based Android apps (e.g., checking location once at app start then relying on cached data for the rest of the day).

---

### 8. Shabbat Period Detection (Window Service)

**Question**: How do we reliably detect the Shabbat window (Friday sunset → Saturday nightfall) without a Hebrew calendar library?

**Decision**: Use the computed **candle lighting time on the current Friday** and **end-of-Shabbat time on the current Saturday** as the window boundaries, derived directly from the already-calculated sunset times.

**Rationale**:
- The Shabbat window is defined entirely by astronomical events (sunset on Friday, nightfall on Saturday) with fixed-minute offsets. No Hebrew calendar library is needed.
- `ShabbatWindowService` determines the current weekday using `Toybox.Time.Gregorian.info()` and applies the boundary times accordingly.
- Edge case: If today is Friday before candle lighting, the service pre-computes the upcoming Shabbat end time using Saturday's sunset (next day's calculation).
- Edge case: If today is Saturday but after nightfall, Shabbat is not active.

---

### 9. KosherJava Algorithm Cross-Reference Table

The following maps KosherJava API methods to the Monkey C implementation:

| KosherJava Method | Monkey C Location | Notes |
|---|---|---|
| `ZmanimCalendar.getSunrise()` | `AstronomicalService._calculateSunriseUTC()` | NOAA algorithm, zenith 90.8333° |
| `ZmanimCalendar.getSunset()` | `SunCalculator.calculateSunsetUTC()` | NOAA algorithm, zenith 90.8333° |
| `ZmanimCalendar.getCandleLighting()` | `ShabbatTimes.getCandleLightingLocalSeconds()` | `sunset - candleOffset` minutes |
| `ZmanimCalendar.getTzais()` | `ShabbatTimes.getShabbatEndLocalSeconds()` | `sunset + endOffset` minutes (default 42) |
| `AstronomicalCalendar.getGeoLocation()` | `LocationService.getLatitude/Longitude()` | GPS or cached location |
| `NOAACalculator` (default calculator) | `SunCalculator.mc` (full class) | NOAA simplified algorithm |
| `AstronomicalCalendar.getSunriseOffsetByDegrees(zenith)` | `SunCalculator.calculateSunriseAtZenithUTC(lat, lon, n, zenith)` | Generic zenith sunrise |
| `AstronomicalCalendar.getSunsetOffsetByDegrees(zenith)` | `SunCalculator.calculateSunsetAtZenithUTC(lat, lon, n, zenith)` | Generic zenith sunset |
| `ComplexZmanimCalendar.getTzaisGeonim8Point5Degrees()` | `SunCalculator.calculateTzaisLocalSeconds(..., "degrees_8_5", ...)` | Zenith 98.5° |
| `ComplexZmanimCalendar.getTzaisGeonim7Point083Degrees()` | `SunCalculator.calculateTzaisLocalSeconds(..., "degrees_7_083", ...)` | Zenith 97.083° |
| `GeoLocation.timeZoneOffset` | `TimezoneService.getUtcOffsetSeconds()` | Device-provided UTC offset |

---

### 10. Hebrew Calendar & Parashat HaShavua Algorithm

**Question**: How do we calculate the current week's Torah portion (Parashat HaShavua) without a Hebrew calendar library on the Garmin CIQ platform?

**Decision**: Implement the **Maimonides / Dershowitz-Reingold molad algorithm** in `HebrewCalendarService.mc` and a **pre-computed schedule table** (6 × 55 entries) in `ParashaService.mc`.

**Rationale**:
- No Hebrew calendar library exists for CIQ (same situation as KosherJava: must port algorithms).
- The molad algorithm is deterministic, pure arithmetic, and requires only `Lang.Long` arithmetic — no floating point.
- Parasha assignment depends on the Hebrew **year type** (deficient/regular/complete × regular/leap = 6 types). A lookup table of 6 × 55 integers (one row per year type, one column per week-of-year) is compact and avoids runtime complexity.
- Offline operation: all data is embedded in the app; no HTTP calls needed. Aligns with Principle V.

**Hebrew Year Types** (used as schedule table index):

| Code | Days | Type        | Description |
|------|------|-------------|-------------|
| 0    | 353  | Deficient regular | Chaser (non-leap) |
| 1    | 354  | Regular regular   | Kesidrah (non-leap) |
| 2    | 355  | Complete regular  | Shalem (non-leap) |
| 3    | 383  | Deficient leap    | Chaser (leap) |
| 4    | 384  | Regular leap      | Kesidrah (leap) |
| 5    | 385  | Complete leap     | Shalem (leap) |

Year type is computed as: `daysInHebrewYear(year) % 10` → 3=deficient, 4=regular, 5=complete.

**7 Double Parashiyot** (Diaspora non-leap years; Israel sometimes reads separately):

| Index | Combined Name | Constituent parashiyot |
|-------|--------------|------------------------|
| 100   | Vayakhel-Pekudei | 21 + 22 |
| 101   | Tazria-Metzora | 26 + 27 |
| 102   | Achrei Mot-Kedoshim | 28 + 29 |
| 103   | Behar-Bechukotai | 31 + 32 |
| 104   | Chukat-Balak | 38 + 39 |
| 105   | Matot-Masei | 41 + 42 |
| 106   | Nitzavim-Vayelech | 50 + 51 |

**Israel vs Diaspora**: In Israel, Yom Tov is 1 day (Diaspora: 2 days). After Pesach in non-leap years, Israel resumes the regular cycle 1 week earlier, causing the two calendars to diverge for several weeks. The `ParashaService` maintains separate `ISRAEL_SCHEDULE` and `DIASPORA_SCHEDULE` tables for non-leap year types (codes 0–2); leap years match.

**Algorithm implementation** (`HebrewCalendarService.mc`):
- `elapsedDaysHebrewYear(year)` — implements 4 Talmudic postponement rules (dehiyyot) in integer arithmetic using `Lang.Long`.
- `isHebrewLeapYear(year)` — `(7*year + 1) % 19 < 7` (Metonic 19-year cycle).
- `gregorianToHebrewYear()` — converts via Julian Day Number; approximates year then refines by 1.
- `hebrewDayOfYear()` — difference in JDs between today and 1 Tishrei.

**KosherJava cross-reference**:

| KosherJava method | Monkey C equivalent |
|---|---|
| `JewishCalendar.getParashahIndex()` | `ParashaService.getParashaIndexForToday(isIsrael)` |
| `JewishDate.getJewishYear()` | `HebrewCalendarService.gregorianToHebrewYear()` |
| `JewishDate.getDayOfYear()` | `HebrewCalendarService.hebrewDayOfYear()` |
| `JewishDate.isJewishLeapYear()` | `HebrewCalendarService.isHebrewLeapYear()` |
| `JewishCalendar.isYomTovAssurBemelacha()` | schedule index = -1 |

**Validation reference**: For any date, cross-check `ParashaService.getParashaName()` against:
- [Hebcal](https://www.hebcal.com/) weekly Torah portion
- [Chabad.org](https://www.chabad.org/calendar/) Shabbat schedule

---

## Summary of Decisions

| # | Decision | Chosen Approach | Key Reason |
|---|----------|----------------|------------|
| 1 | Library usage | Port algorithms, do not use KosherJava jar | No JVM on Garmin CIQ |
| 2 | Solar algorithm | NOAA Simplified (same as KosherJava default) | ±1 min accuracy; well-tested |
| 3 | Candle lighting | `sunset − N min` (default 18) | Matches KosherJava `getCandleLighting()` |
| 4 | Tzais / end of Shabbat | Fixed minutes (default 42), zenith-based optional | Simplicity + correctness for typical users |
| 5 | Float precision | 32-bit floats (native CIQ) | Sufficient; physics limits ±2 min anyway |
| 6 | Timezone | `System.getDeviceSettings().timeZoneOffset` | Native API; DST-aware |
| 7 | GPS polling | 5 min normal / 30 min Shabbat | Battery efficiency + SC-006 compliance |
| 8 | Shabbat window | Gregorian weekday + sunset times | No Hebrew calendar library needed |
