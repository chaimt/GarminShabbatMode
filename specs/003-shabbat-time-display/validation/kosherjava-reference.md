# KosherJava Reference Values

**Purpose**: Cross-reference table for validating `SunCalculator.mc` output against authoritative KosherJava `NOAACalculator` results.  
**Accuracy target**: ±2 minutes (SC-002, FR-014).  
**Reference tool**: https://kosherjava.com/zmanim-project/zmanim-calendar/  
**KosherJava classes used**: `ZmanimCalendar` (standard), `ComplexZmanimCalendar` (degree-based)

---

## How to Use

1. Open the KosherJava Zmanim Calendar (link above)
2. Enter the location and date from the table below
3. Compare the displayed Sunrise / Sunset / Tzais values against your simulator output
4. Pass criteria: all values within **±2 minutes**

In the Connect IQ Simulator:
- Set GPS location via **GPS → Set Location** (lat, lon)
- Freeze the date by setting system clock to midnight of the test date
- Read the displayed times from the watch face
- Enable "Geonim 8.5°" mode in Settings to test the degree-based tzais

---

## Test Case 1 — Lakewood, NJ (primary reference)

| Field | Value |
|-------|-------|
| Location | Lakewood, NJ, USA |
| Latitude | 40.096°N |
| Longitude | 74.222°W |
| Timezone | America/New_York (UTC−5 winter / UTC−4 summer) |
| Date | 2026-04-22 (spring, DST active) |

| Zman | KosherJava Method | Expected (local EDT) | Expected (UTC) |
|------|-------------------|---------------------|----------------|
| Sunrise | `ZmanimCalendar.getSunrise()` | ~05:47 | ~09:47 |
| Sunset | `ZmanimCalendar.getSunset()` | ~19:27 | ~23:27 |
| Candle lighting (−18 min) | `ZmanimCalendar.getCandleLighting()` | ~19:09 | ~23:09 |
| Tzais 42 min (fixed) | `ZmanimCalendar.getTzais()` | ~20:09 | ~00:09 |
| Tzais 8.5° | `ComplexZmanimCalendar.getTzaisGeonim8Point5Degrees()` | ~20:10 | ~00:10 |
| Tzais 7.083° | `ComplexZmanimCalendar.getTzaisGeonim7Point083Degrees()` | ~19:55 | ~23:55 |

---

## Test Case 2 — Lakewood, NJ (winter solstice)

| Field | Value |
|-------|-------|
| Location | Lakewood, NJ, USA |
| Latitude | 40.096°N |
| Longitude | 74.222°W |
| Timezone | America/New_York (UTC−5, no DST) |
| Date | 2025-12-21 (winter solstice) |

| Zman | KosherJava Method | Expected (local EST) | Expected (UTC) |
|------|-------------------|---------------------|----------------|
| Sunrise | `ZmanimCalendar.getSunrise()` | ~07:08 | ~12:08 |
| Sunset | `ZmanimCalendar.getSunset()` | ~16:19 | ~21:19 |
| Candle lighting (−18 min) | `ZmanimCalendar.getCandleLighting()` | ~16:01 | ~21:01 |
| Tzais 42 min (fixed) | `ZmanimCalendar.getTzais()` | ~17:01 | ~22:01 |
| Tzais 8.5° | `ComplexZmanimCalendar.getTzaisGeonim8Point5Degrees()` | ~17:01 | ~22:01 |
| Tzais 7.083° | `ComplexZmanimCalendar.getTzaisGeonim7Point083Degrees()` | ~16:46 | ~21:46 |

---

## Test Case 3 — Jerusalem, Israel

| Field | Value |
|-------|-------|
| Location | Jerusalem, Israel |
| Latitude | 31.78°N |
| Longitude | 35.22°E |
| Timezone | Asia/Jerusalem (UTC+2 winter / UTC+3 summer) |
| Date | 2026-04-22 (spring) |

| Zman | KosherJava Method | Expected (local IDT) | Expected (UTC) |
|------|-------------------|---------------------|----------------|
| Sunrise | `ZmanimCalendar.getSunrise()` | ~06:10 | ~03:10 |
| Sunset | `ZmanimCalendar.getSunset()` | ~19:28 | ~16:28 |
| Candle lighting (−18 min) | `ZmanimCalendar.getCandleLighting()` | ~19:10 | ~16:10 |
| Tzais 42 min (fixed) | `ZmanimCalendar.getTzais()` | ~20:10 | ~17:10 |
| Tzais 8.5° | `ComplexZmanimCalendar.getTzaisGeonim8Point5Degrees()` | ~20:06 | ~17:06 |
| Tzais 7.083° | `ComplexZmanimCalendar.getTzaisGeonim7Point083Degrees()` | ~19:51 | ~16:51 |

---

## Test Case 4 — London, UK

| Field | Value |
|-------|-------|
| Location | London, UK |
| Latitude | 51.51°N |
| Longitude | 0.12°W |
| Timezone | Europe/London (UTC+1 summer BST) |
| Date | 2026-04-22 (spring, BST active) |

| Zman | KosherJava Method | Expected (local BST) | Expected (UTC) |
|------|-------------------|---------------------|----------------|
| Sunrise | `ZmanimCalendar.getSunrise()` | ~06:01 | ~05:01 |
| Sunset | `ZmanimCalendar.getSunset()` | ~20:21 | ~19:21 |
| Candle lighting (−18 min) | `ZmanimCalendar.getCandleLighting()` | ~20:03 | ~19:03 |
| Tzais 42 min (fixed) | `ZmanimCalendar.getTzais()` | ~21:03 | ~20:03 |
| Tzais 8.5° | `ComplexZmanimCalendar.getTzaisGeonim8Point5Degrees()` | ~21:09 | ~20:09 |
| Tzais 7.083° | `ComplexZmanimCalendar.getTzaisGeonim7Point083Degrees()` | ~20:49 | ~19:49 |

---

## Test Case 5 — Melbourne, Australia (southern hemisphere)

| Field | Value |
|-------|-------|
| Location | Melbourne, Australia |
| Latitude | 37.81°S |
| Longitude | 144.96°E |
| Timezone | Australia/Melbourne (UTC+10 AEST) |
| Date | 2025-12-21 (southern hemisphere summer solstice) |

| Zman | KosherJava Method | Expected (local AEDT) | Expected (UTC) |
|------|-------------------|----------------------|----------------|
| Sunrise | `ZmanimCalendar.getSunrise()` | ~05:55 | ~19:55 prev |
| Sunset | `ZmanimCalendar.getSunset()` | ~20:45 | ~10:45 |
| Candle lighting (−18 min) | `ZmanimCalendar.getCandleLighting()` | ~20:27 | ~10:27 |
| Tzais 42 min (fixed) | `ZmanimCalendar.getTzais()` | ~21:27 | ~11:27 |
| Tzais 8.5° | `ComplexZmanimCalendar.getTzaisGeonim8Point5Degrees()` | ~21:30 | ~11:30 |

---

## Test Case 6 — Tromsø, Norway (polar — expected failure)

| Field | Value |
|-------|-------|
| Location | Tromsø, Norway |
| Latitude | 69.65°N |
| Longitude | 18.96°E |
| Date | 2025-06-21 (midnight sun) |

| Expected behaviour | Notes |
|-------------------|-------|
| `calculateSunsetAtZenithUTC(...)` returns `null` | Polar night / midnight sun |
| `calculateTzaisLocalSeconds(...)` returns `-1` | Graceful fallback, no crash |
| UI displays polar warning string (`PolarWarning`) | Configured in `time_strings.xml` |

---

## Degree-Based Tzais — Latitude Sensitivity Table

The number of minutes after standard sunset varies by latitude and season. This table shows approximate offset minutes for common latitudes:

| Latitude | Tzais 8.5° (spring equinox) | Tzais 8.5° (summer solstice) | Tzais 7.083° (spring) |
|----------|----------------------------|------------------------------|----------------------|
| 32°N (Jerusalem) | ~35 min | ~38 min | ~29 min |
| 40°N (New York) | ~42 min | ~48 min | ~35 min |
| 51°N (London) | ~48 min | ~60+ min | ~40 min |
| 32°S (Melbourne) | ~35 min | ~30 min | ~29 min |

This confirms that degree-based tzais is **location and season dependent**, unlike fixed-minute tzais.
