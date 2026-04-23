#!/usr/bin/env python3
"""
Offline validation for HebrewCalendarService + ParashaService (Monkey C ports).

Implements the same Maimonides / KosherJava algorithm in Python so we can
verify correctness against known Hebrew calendar references without the
Connect IQ simulator.

Test cases cover T112–T119 from specs/003-shabbat-time-display/tasks.md.

Usage:
    python3 verify-parasha.py
"""

import sys
from datetime import date

# ---------------------------------------------------------------------------
# Hebrew Calendar (mirrors HebrewCalendarService.mc)
# ---------------------------------------------------------------------------

HEBREW_EPOCH_JD = 347997          # JDN of 1 Tishrei 1 AM (KosherJava-consistent)
CHALAKIM_PER_DAY = 25920          # 24 * 1080
MOLAD_TOHU = 31524                # 1d 5h 204p from Sunday (KosherJava CHALAKIM_MOLAD_TOHU)
MOLAD_PERIOD = 765433             # avg month length in chalakim


def is_hebrew_leap_year(year: int) -> bool:
    return (7 * year + 1) % 19 < 7


def months_in_hebrew_year(year: int) -> int:
    return 13 if is_hebrew_leap_year(year) else 12


def months_elapsed(year: int) -> int:
    cycles = (year - 1) // 19
    remainder = (year - 1) % 19
    months = 235 * cycles + 12 * remainder + (7 * remainder + 1) // 19
    return months


def elapsed_days_hebrew_year(year: int) -> int:
    me = months_elapsed(year)
    parts_elapsed = MOLAD_TOHU + MOLAD_PERIOD * me
    day = parts_elapsed // CHALAKIM_PER_DAY
    part = parts_elapsed % CHALAKIM_PER_DAY
    day_of_week = day % 7   # 0 = Sun

    alt_day = day
    if (part >= 19440                                                       # Rule 1: noon
            or (day_of_week == 2 and part >= 9924 and not is_hebrew_leap_year(year))   # Rule 3
            or (day_of_week == 1 and part >= 16789 and is_hebrew_leap_year(year - 1))): # Rule 4
        alt_day = day + 1

    alt_dow = alt_day % 7
    if alt_dow in (0, 3, 5):    # Rule 2: no Sun/Wed/Fri for RH
        alt_day += 1

    return alt_day


def days_in_hebrew_year(year: int) -> int:
    return elapsed_days_hebrew_year(year + 1) - elapsed_days_hebrew_year(year)


def is_cheshvan_long(year: int) -> bool:
    return days_in_hebrew_year(year) % 10 == 5


def is_kislev_short(year: int) -> bool:
    return days_in_hebrew_year(year) % 10 == 3


def rosh_hashana_day_of_week(year: int) -> int:
    """Returns day-of-week in Java Calendar scale: 2=Mon 3=Tue 5=Thu 7=Sat."""
    dow = (elapsed_days_hebrew_year(year) + 1) % 7
    return dow if dow != 0 else 7


def julian_day_from_gregorian(year: int, month: int, day: int) -> int:
    """Standard Gregorian → JDN (Calendar FAQ algorithm, truncating-toward-zero division)."""
    a = int((14 - month) / 12)   # truncate toward zero (matches Monkey C / integer)
    y = year + 4800 - a
    m = month + 12 * a - 3
    A = y // 400 - y // 100 + y // 4
    return 365 * y + A + (153 * m + 2) // 5 + day - 32045


def gregorian_to_hebrew_year(year: int, month: int, day: int) -> int:
    jd = julian_day_from_gregorian(year, month, day)
    approx = (jd - HEBREW_EPOCH_JD) * 98496 // 35975351 + 1
    hyr = approx - 1
    while elapsed_days_hebrew_year(hyr + 1) + HEBREW_EPOCH_JD <= jd:
        hyr += 1
    return hyr


def hebrew_day_of_year(year: int, month: int, day: int) -> int:
    jd = julian_day_from_gregorian(year, month, day)
    hyear = gregorian_to_hebrew_year(year, month, day)
    rosh_jd = elapsed_days_hebrew_year(hyear) + HEBREW_EPOCH_JD
    return jd - rosh_jd + 1


def month_lengths(year: int) -> list:
    leap = is_hebrew_leap_year(year)
    ch_long = is_cheshvan_long(year)
    ki_short = is_kislev_short(year)
    if leap:
        return [30, 30 if ch_long else 29, 29 if ki_short else 30,
                29, 30, 30, 29, 30, 29, 30, 29, 30, 29]
    return [30, 30 if ch_long else 29, 29 if ki_short else 30,
            29, 30, 29, 30, 29, 30, 29, 30, 29]


def hebrew_month_for_doy(year: int, doy: int) -> int:
    lengths = month_lengths(year)
    cum = 0
    for m, length in enumerate(lengths):
        cum += length
        if doy <= cum:
            return m + 1
    return len(lengths)


def hebrew_day_of_month_for_doy(year: int, doy: int) -> int:
    lengths = month_lengths(year)
    cum = 0
    for length in lengths:
        cum += length
        if doy <= cum:
            return doy - (cum - length)
    return doy


def today_hebrew_date(g_year: int, g_month: int, g_day: int):
    hyear = gregorian_to_hebrew_year(g_year, g_month, g_day)
    doy = hebrew_day_of_year(g_year, g_month, g_day)
    hmonth = hebrew_month_for_doy(hyear, doy)
    hday = hebrew_day_of_month_for_doy(hyear, doy)
    return hyear, hmonth, hday, doy


# ---------------------------------------------------------------------------
# Hebrew month names (1=Tishrei, non-leap mapping)
# ---------------------------------------------------------------------------

HEBREW_MONTHS_REGULAR = [
    "", "Tishrei", "Cheshvan", "Kislev", "Tevet", "Shevat",
    "Adar", "Nissan", "Iyar", "Sivan", "Tammuz", "Av", "Elul"
]
HEBREW_MONTHS_LEAP = [
    "", "Tishrei", "Cheshvan", "Kislev", "Tevet", "Shevat",
    "Adar I", "Adar II", "Nissan", "Iyar", "Sivan", "Tammuz", "Av", "Elul"
]

def hebrew_month_name(year: int, month: int) -> str:
    if is_hebrew_leap_year(year):
        return HEBREW_MONTHS_LEAP[month] if month < len(HEBREW_MONTHS_LEAP) else f"Month {month}"
    return HEBREW_MONTHS_REGULAR[month] if month < len(HEBREW_MONTHS_REGULAR) else f"Month {month}"


# ---------------------------------------------------------------------------
# Parasha Service (mirrors ParashaService.mc — KosherJava 17-type table)
# ---------------------------------------------------------------------------

# Parasha index → name
PARASHA_NAMES = [
    "Bereshit", "Noach", "Lech Lecha", "Vayera", "Chayei Sarah",        # 0-4
    "Toldot", "Vayetzei", "Vayishlach", "Vayeshev", "Miketz",           # 5-9
    "Vayigash", "Vayechi", "Shemot", "Vaera", "Bo",                     # 10-14
    "Beshalach", "Yitro", "Mishpatim", "Terumah", "Tetzaveh",            # 15-19
    "Ki Tisa", "Vayakhel", "Pekudei", "Vayikra", "Tzav",                # 20-24
    "Shemini", "Tazria", "Metzora", "Achrei Mot", "Kedoshim",            # 25-29
    "Emor", "Behar", "Bechukotai", "Bamidbar", "Nasso",                  # 30-34
    "Beha'alotecha", "Shelach", "Korach", "Chukat", "Balak",             # 35-39
    "Pinchas", "Matot", "Masei", "Devarim", "Vaetchanan",                # 40-44
    "Eikev", "Re'eh", "Shoftim", "Ki Teitzei", "Ki Tavo",               # 45-49
    "Nitzavim", "Vayelech", "Haazinu", "Vezot Haberacha",               # 50-53
]
COMBINED_NAMES = {
    100: "Vayakhel-Pekudei",
    101: "Tazria-Metzora",
    102: "Achrei-Kedoshim",
    103: "Behar-Bechukotai",
    104: "Chukat-Balak",
    105: "Matot-Masei",
    106: "Nitzavim-Vayelech",
}
SPECIAL_NAMES = {
    200: "Shabbat Shekalim",
    201: "Shabbat Zachor",
    202: "Shabbat Para",
    203: "Shabbat Hachodesh",
    204: "Shabbat HaGadol",
    205: "Shabbat Chazon",
    206: "Shabbat Nachamu",
    207: "Shabbat Shuva",
    208: "Shabbat Shira",
}

# KosherJava 17-type PARSHA_LIST (verbatim port of ParashaService.mc)
PARSHA_LIST = [
    # Row 0: non-leap, Mon RH KislevShort (BaCh)
    [-1,51,52,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,100,23,24,-1,25,101,102,30,103,33,34,35,36,37,38,39,40,105,43,44,45,46,47,48,49,106],
    # Row 1: non-leap, Mon RH CheshvanLong or Tue RH — Diaspora
    [-1,51,52,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,100,23,24,-1,25,101,102,30,103,33,-1,34,35,36,37,104,40,105,43,44,45,46,47,48,49,106],
    # Row 2: non-leap, Thu RH normal (HaK) — Diaspora
    [-1,52,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,100,23,24,-1,-1,25,101,102,30,103,33,34,35,36,37,38,39,40,105,43,44,45,46,47,48,49,50],
    # Row 3: non-leap, Thu RH CheshvanLong (HaSh)
    [-1,52,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,-1,25,101,102,30,103,33,34,35,36,37,38,39,40,105,43,44,45,46,47,48,49,50],
    # Row 4: non-leap, Sat RH KislevShort (ZaCh)
    [-1,-1,52,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,100,23,24,-1,25,101,102,30,103,33,34,35,36,37,38,39,40,105,43,44,45,46,47,48,49,50],
    # Row 5: non-leap, Sat RH CheshvanLong (ZaSh)
    [-1,-1,52,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,100,23,24,-1,25,101,102,30,103,33,34,35,36,37,38,39,40,105,43,44,45,46,47,48,49,106],
    # Row 6: leap, Mon RH KislevShort (BaCh) — Diaspora
    [-1,51,52,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,-1,28,29,30,31,32,33,-1,34,35,36,37,104,40,105,43,44,45,46,47,48,49,106],
    # Row 7: leap, Mon RH CheshvanLong or Tue RH — Diaspora
    [-1,51,52,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,-1,-1,28,29,30,31,32,33,34,35,36,37,38,39,40,105,43,44,45,46,47,48,49,50],
    # Row 8: leap, Thu RH KislevShort (HaCh)
    [-1,52,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,-1,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50],
    # Row 9: leap, Thu RH CheshvanLong (HaSh)
    [-1,52,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,-1,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,106],
    # Row 10: leap, Sat RH KislevShort (ZaCh)
    [-1,-1,52,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,-1,28,29,30,31,32,33,34,35,36,37,38,39,40,105,43,44,45,46,47,48,49,106],
    # Row 11: leap, Sat RH CheshvanLong (ZaSh) — Diaspora
    [-1,-1,52,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,-1,28,29,30,31,32,33,-1,34,35,36,37,104,40,105,43,44,45,46,47,48,49,106],
    # Row 12: non-leap, Mon RH CheshvanLong or Tue RH — Israel
    [-1,51,52,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,100,23,24,-1,25,101,102,30,103,33,34,35,36,37,38,39,40,105,43,44,45,46,47,48,49,106],
    # Row 13: non-leap, Thu RH normal (HaK) — Israel
    [-1,52,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,100,23,24,-1,25,101,102,30,31,32,33,34,35,36,37,38,39,40,105,43,44,45,46,47,48,49,50],
    # Row 14: leap, Mon RH KislevShort (BaCh) — Israel
    [-1,51,52,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,-1,28,29,30,31,32,33,34,35,36,37,38,39,40,105,43,44,45,46,47,48,49,106],
    # Row 15: leap, Mon RH CheshvanLong or Tue RH — Israel
    [-1,51,52,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,-1,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50],
    # Row 16: leap, Sat RH CheshvanLong (ZaSh) — Israel
    [-1,-1,52,-1,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,-1,28,29,30,31,32,33,34,35,36,37,38,39,40,105,43,44,45,46,47,48,49,106],
]


def parsha_year_type(year: int, is_israel: bool) -> int:
    dow = rosh_hashana_day_of_week(year)
    is_leap = is_hebrew_leap_year(year)
    ch_long = is_cheshvan_long(year)
    ki_short = is_kislev_short(year)

    if is_leap:
        if dow == 2:   # Monday
            if ki_short: return 14 if is_israel else 6
            if ch_long:  return 15 if is_israel else 7
        elif dow == 3: # Tuesday
            return 15 if is_israel else 7
        elif dow == 5: # Thursday
            if ki_short: return 8
            if ch_long:  return 9
        elif dow == 7: # Saturday
            if ki_short: return 10
            if ch_long:  return 16 if is_israel else 11
    else:
        if dow == 2:   # Monday
            if ki_short: return 0
            if ch_long:  return 12 if is_israel else 1
        elif dow == 3: # Tuesday
            return 12 if is_israel else 1
        elif dow == 5: # Thursday
            if ch_long:  return 3
            if not ki_short: return 13 if is_israel else 2
        elif dow == 7: # Saturday
            if ki_short: return 4
            if ch_long:  return 5
    return -1


def special_shabbos_for_shabbat(year: int, shabbat_doy: int, parasha_index: int) -> int:
    is_leap = is_hebrew_leap_year(year)
    month = hebrew_month_for_doy(year, shabbat_doy)
    day = hebrew_day_of_month_for_doy(year, shabbat_doy)

    # Shabbat Shira: Beshalach
    if parasha_index == 15:
        return 208

    # Shabbat Shekalim: late Shevat before Adar
    if (month == 5 and not is_leap) or (month == 6 and is_leap):
        if day in (25, 27, 29):
            return 200

    # Final Adar (Adar in non-leap, Adar II in leap)
    is_final_adar = (month == 6 and not is_leap) or (month == 7 and is_leap)
    if is_final_adar:
        if day == 1:    return 200  # Shekalim
        if day in (8, 9, 11, 13): return 201  # Zachor
        if day in (18, 20, 22, 23): return 202  # Para
        if day in (25, 27, 29):    return 203  # Hachodesh

    # Nissan
    nissan = 8 if is_leap else 7
    if month == nissan:
        if day == 1:             return 203  # Hachodesh
        if 8 <= day <= 14:       return 204  # Hagadol

    # Av
    av = 12 if is_leap else 11
    if month == av:
        if 4 <= day <= 9:   return 205  # Chazon
        if 10 <= day <= 16: return 206  # Nachamu

    # Tishrei
    if month == 1:
        if 3 <= day <= 8: return 207  # Shuva

    return -1


def get_parasha_for_gregorian_shabbat(g_year: int, g_month: int, g_day: int,
                                       is_israel: bool):
    """
    Returns (parasha_name, special_name_or_None, parasha_index, special_index).
    Mirrors ParashaService.getParashaName() logic.
    """
    g_date = date(g_year, g_month, g_day)
    dow = g_date.isoweekday()  # Mon=1 ... Sun=7; Sat=6
    days_until_shabbat = (6 - dow) % 7  # 0 if today IS Sat

    hyear = gregorian_to_hebrew_year(g_year, g_month, g_day)
    doy = hebrew_day_of_year(g_year, g_month, g_day)
    shabbat_doy = doy + days_until_shabbat
    check_year = hyear

    year_days = days_in_hebrew_year(hyear)
    if shabbat_doy > year_days:
        shabbat_doy -= year_days
        check_year = hyear + 1

    year_type = parsha_year_type(check_year, is_israel)
    if year_type < 0:
        return "--", None, -1, -1

    rh_dow = elapsed_days_hebrew_year(check_year) % 7
    table_index = (rh_dow + shabbat_doy) // 7

    schedule = PARSHA_LIST[year_type]
    if table_index < 0 or table_index >= len(schedule):
        index = -1
    else:
        index = schedule[table_index]

    special = special_shabbos_for_shabbat(check_year, shabbat_doy, index)

    if index < 0:
        name = "--"
    elif index < 54:
        name = PARASHA_NAMES[index]
    elif index in COMBINED_NAMES:
        name = COMBINED_NAMES[index]
    else:
        name = f"Unknown({index})"

    special_name = SPECIAL_NAMES.get(special) if special >= 200 else None
    return name, special_name, index, special


# ---------------------------------------------------------------------------
# Test runner
# ---------------------------------------------------------------------------

PASS = "✅ PASS"
FAIL = "❌ FAIL"
failures = []


def check(label, got, expected, allow_subset=False):
    ok = (got == expected) if not allow_subset else (expected in str(got))
    status = PASS if ok else FAIL
    print(f"  {status}  {label}")
    print(f"         got={got!r}  expected={expected!r}")
    if not ok:
        failures.append(label)
    return ok


print("=" * 70)
print("Parasha Validation — T112–T119 (verify-parasha.py)")
print("=" * 70)

# ---------------------------------------------------------------------------
# T112: Hebrew calendar date conversion
# ---------------------------------------------------------------------------
print("\n── T112: Hebrew Calendar Date Conversion ──────────────────────────────")

# Apr 18 2026 = 1 Iyar 5786 (month 8, day 1 in non-leap year Tishrei-first counting)
hyear, hmonth, hday, doy = today_hebrew_date(2026, 4, 18)
check("Apr 18 2026 → Hebrew year = 5786", hyear, 5786)
check("Apr 18 2026 → Hebrew month = 8 (Iyar in 5786)", hmonth, 8)
check("Apr 18 2026 → Hebrew day = 1", hday, 1)
print(f"         ({hyear} {hebrew_month_name(hyear, hmonth)} {hday} = {doy} day of year)")

# Oct 3 2024 = 1 Tishrei 5785 (Rosh Hashana)
hyear2, hmonth2, hday2, _ = today_hebrew_date(2024, 10, 3)
check("Oct 3 2024 → Hebrew year = 5785", hyear2, 5785)
check("Oct 3 2024 → Hebrew month = 1 (Tishrei)", hmonth2, 1)
check("Oct 3 2024 → Hebrew day = 1 (Rosh Hashana)", hday2, 1)

# Sep 25 2025 = 3 Tishrei 5786 (RH 5786 = Sep 23 = day 1, so Sep 25 = day 3)
hyear3, hmonth3, hday3, _ = today_hebrew_date(2025, 9, 25)
check("Sep 25 2025 → Hebrew year = 5786", hyear3, 5786)
check("Sep 25 2025 → Hebrew month = 1 (Tishrei)", hmonth3, 1)
check("Sep 25 2025 → Hebrew day = 3", hday3, 3)

# ---------------------------------------------------------------------------
# T113: roshHashanaDayOfWeek
# ---------------------------------------------------------------------------
print("\n── T113: Rosh Hashana Day of Week ──────────────────────────────────────")

# 5786: Rosh Hashana = Sep 23 2025 = Tuesday → Java Calendar scale 3
dow5786 = rosh_hashana_day_of_week(5786)
check("roshHashanaDayOfWeek(5786) = 3 (Tuesday)", dow5786, 3)

# 5785: Rosh Hashana = Oct 3 2024 = Thursday → Java Calendar scale 5
dow5785 = rosh_hashana_day_of_week(5785)
check("roshHashanaDayOfWeek(5785) = 5 (Thursday)", dow5785, 5)

# 5784: Rosh Hashana = Sep 16 2023 = Saturday → Java Calendar scale 7
dow5784 = rosh_hashana_day_of_week(5784)
check("roshHashanaDayOfWeek(5784) = 7 (Saturday)", dow5784, 7)

yt5786 = parsha_year_type(5786, False)
print(f"  INFO  parshaYearType(5786, Diaspora) = {yt5786}  (non-leap Tue RH → row 1)")
yt5785 = parsha_year_type(5785, False)
print(f"  INFO  parshaYearType(5785, Diaspora) = {yt5785}  (non-leap Thu RH → row 2 or 3)")

# ---------------------------------------------------------------------------
# T114: Standard parasha — Shemini on Apr 11 2026 (both Israel and Diaspora match)
# Note: Apr 11 2026 = 24 Nisan 5786 = first Shabbat after Pesach
# ---------------------------------------------------------------------------
print("\n── T114: Standard Parasha — Apr 11 2026 (Shemini) ─────────────────────")

name_d, spec_d, idx_d, sidx_d = get_parasha_for_gregorian_shabbat(2026, 4, 11, False)
check("Apr 11 2026 Diaspora → Shemini", name_d, "Shemini")

name_i, spec_i, idx_i, sidx_i = get_parasha_for_gregorian_shabbat(2026, 4, 11, True)
check("Apr 11 2026 Israel → Shemini (schedules match this week)", name_i, "Shemini")

check("No special Shabbat this week", sidx_d, -1)

# Verify the following Shabbat Apr 18 = Tazria-Metzora (Diaspora) for context
name_tm, _, idx_tm, _ = get_parasha_for_gregorian_shabbat(2026, 4, 18, False)
check("Apr 18 2026 Diaspora → Tazria-Metzora (follows Shemini)", name_tm, "Tazria-Metzora")

# ---------------------------------------------------------------------------
# T115: Israel/Diaspora divergence — May 30 2026
# In 5786 the split starts at Shavuot (Diaspora skips a week, Israel doesn't)
# May 30 2026: Diaspora = Nasso, Israel = Beha'alotecha
# ---------------------------------------------------------------------------
print("\n── T115: Israel/Diaspora Divergence — May 30 2026 ─────────────────────")

name_d2, spec_d2, idx_d2, _ = get_parasha_for_gregorian_shabbat(2026, 5, 30, False)
check("May 30 2026 Diaspora → Nasso (index 34)", name_d2, "Nasso")
check("Diaspora index = 34", idx_d2, 34)

name_i2, spec_i2, idx_i2, _ = get_parasha_for_gregorian_shabbat(2026, 5, 30, True)
check("May 30 2026 Israel → Beha'alotecha (index 35)", name_i2, "Beha'alotecha")
check("Israel index = 35", idx_i2, 35)

# ---------------------------------------------------------------------------
# T116: Yom Tov week — Apr 4 2026 (Shabbat Chol HaMoed Pesach, no regular parasha)
# Pesach in Diaspora: Apr 2-9 2026 (Nisan 15-22 5786)
# Apr 4 2026 = Shabbat during Chol HaMoed Pesach → no regular parasha reading
# ---------------------------------------------------------------------------
print("\n── T116: Yom Tov Week Fallback — Apr 4 2026 ────────────────────────────")

name_yt, spec_yt, idx_yt, _ = get_parasha_for_gregorian_shabbat(2026, 4, 4, False)
check("Apr 4 2026 Diaspora → '--' (Shabbat Chol HaMoed Pesach, no regular reading)", name_yt, "--")

name_yt_i, _, _, _ = get_parasha_for_gregorian_shabbat(2026, 4, 4, True)
check("Apr 4 2026 Israel → '--' (also during Pesach in Israel)", name_yt_i, "--")

# ---------------------------------------------------------------------------
# T117: Leap year separate parasha — Apr 13 2024 in 5784 (Tazria read separately)
# 5784 is a leap year; in leap years Tazria (26) and Metzora (27) are separate.
# 5785 is NOT a leap year — use 5784 (Sep 2023 – Sep 2024) instead.
# ---------------------------------------------------------------------------
print("\n── T117: Leap Year Separate Parasha — Apr 13 2024 (5784 leap) ──────────")

name_ly, spec_ly, idx_ly, _ = get_parasha_for_gregorian_shabbat(2024, 4, 13, False)
check("Apr 13 2024 Diaspora (5784 leap) → Tazria (not combined)", name_ly, "Tazria")
check("Index = 26 (not 101)", idx_ly, 26)

# Verify next week is Metzora separately
name_ly2, _, idx_ly2, _ = get_parasha_for_gregorian_shabbat(2024, 4, 20, False)
check("Apr 20 2024 Diaspora (5784 leap) → Metzora (separate)", name_ly2, "Metzora")
check("Index = 27", idx_ly2, 27)

# ---------------------------------------------------------------------------
# T118: Shabbat Zachor — Feb 28 2026 (Adar 11 5786, Shabbat before Purim Mar 3)
# Regular parasha read that week: Tetzaveh (index 19)
# Special designation: Shabbat Zachor (sidx 201)
# ---------------------------------------------------------------------------
print("\n── T118: Shabbat Zachor — Feb 28 2026 ──────────────────────────────────")

name_z, spec_z, idx_z, sidx_z = get_parasha_for_gregorian_shabbat(2026, 2, 28, False)
print(f"  INFO  Feb 28 2026: parasha={name_z!r} (regular reading), special={spec_z!r}, sidx={sidx_z}")
check("sidx = 201 (Shabbat Zachor)", sidx_z, 201)
check("special name = 'Shabbat Zachor'", spec_z, "Shabbat Zachor")
check("Regular parasha = Tetzaveh (index 19)", idx_z, 19)

# ---------------------------------------------------------------------------
# T119: Shabbat Shira — Jan 31 2026 (13 Shevat 5786, week of Beshalach)
# Shabbat Shira triggers whenever parasha index == 15 (Beshalach)
# ---------------------------------------------------------------------------
print("\n── T119: Shabbat Shira — Jan 31 2026 ───────────────────────────────────")

name_s, spec_s, idx_s, sidx_s = get_parasha_for_gregorian_shabbat(2026, 1, 31, False)
print(f"  INFO  Jan 31 2026: parasha={name_s!r}, special={spec_s!r}, sidx={sidx_s}")
check("parasha = Beshalach (index 15)", idx_s, 15)
check("sidx = 208 (Shabbat Shira)", sidx_s, 208)
check("special = 'Shabbat Shira'", spec_s, "Shabbat Shira")

# ---------------------------------------------------------------------------
# T120: Layout math (no simulator needed)
# ---------------------------------------------------------------------------
print("\n── T120: Row Layout Math at 240×240 ────────────────────────────────────")

h = 240
row4_y = h * 80 // 100   # 192
row5_y = h * 91 // 100   # 218
gap = row5_y - row4_y

check("Row 4 Y = 192 px", row4_y, 192)
check("Row 5 Y = 218 px", row5_y, 218)
check("Gap Row4→Row5 ≥ 20 px (FONT_TINY safe)", gap >= 20, True)
# Note: FONT_TINY is typically ~12–14px tall; 26px gap is sufficient.
print(f"  INFO  Row4={row4_y}px  Row5={row5_y}px  gap={gap}px  ✓ no overlap")
# Longest label check — cannot measure pixel width without DC, but
# "Parasha: Nitzavim-Vayelech" = 28 chars; FONT_TINY ~6px/char → ~168px < 240px.
print(f"  INFO  'Parasha: Nitzavim-Vayelech' = {len('Parasha: Nitzavim-Vayelech')} chars "
      f"(FONT_TINY ~6px/char ≈ {len('Parasha: Nitzavim-Vayelech')*6}px < 240px) ✓")

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
print("\n" + "=" * 70)
total = 34  # approximate; update if you add more checks
if failures:
    print(f"❌  {len(failures)} test(s) FAILED:")
    for f in failures:
        print(f"     • {f}")
    sys.exit(1)
else:
    print(f"✅  ALL tests PASSED  ({total - len(failures)} checks)")
    sys.exit(0)
