using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Time;
using Toybox.Time.Gregorian;

// Determines the current week's Parashat HaShavua (weekly Torah portion)
// and any special Shabbat designation using the KosherJava algorithm.
//
// Parasha indices 0–53 map to the 54 standard portions.
// Combined (double) parashiyot use indices 100–106:
//   100 = Vayakhel-Pekudei
//   101 = Tazria-Metzora
//   102 = Achrei Mot-Kedoshim
//   103 = Behar-Bechukotai
//   104 = Chukat-Balak
//   105 = Matot-Masei
//   106 = Nitzavim-Vayelech
// Index -1 = Yom Tov / Moadim week (no regular portion read).
//
// Special Shabbatot use indices 200–208:
//   200 = Shekalim,  201 = Zachor,  202 = Para,  203 = Hachodesh,
//   204 = Hagadol,   205 = Chazon,  206 = Nachamu, 207 = Shuva, 208 = Shira
//
// Algorithm: KosherJava JewishCalendar.getParshah() /
//            JewishCalendar.getParshaYearType() from the zmanim library.
//            17 year-type table indexed by (roshHashanaDow + shabbatDayOfYear) / 7.
//
// Year-type mapping (matches KosherJava Java Calendar constants: MONDAY=2, TUESDAY=3,
// THURSDAY=5, SATURDAY=7):
//   Non-leap:
//     0: Mon RH KislevShort (BaCh)
//     1: Mon RH CheshvanLong (BaSh) or Tue RH (GaK) — Diaspora
//     2: Thu RH normal (HaK) — Diaspora
//     3: Thu RH CheshvanLong (HaSh)
//     4: Sat RH KislevShort (ZaCh)
//     5: Sat RH CheshvanLong (ZaSh)
//    12: Mon RH CheshvanLong or Tue RH — Israel
//    13: Thu RH normal (HaK) — Israel
//   Leap:
//     6: Mon RH KislevShort — Diaspora
//     7: Mon RH CheshvanLong or Tue RH — Diaspora
//     8: Thu RH KislevShort (HaCh)
//     9: Thu RH CheshvanLong (HaSh)
//    10: Sat RH KislevShort (ZaCh)
//    11: Sat RH CheshvanLong — Diaspora
//    14: Mon RH KislevShort — Israel
//    15: Mon RH CheshvanLong or Tue RH — Israel
//    16: Sat RH CheshvanLong — Israel
class ParashaService {

    // Parasha index → Rez.Strings key name (string, loaded at runtime).
    private static const PARASHA_STRING_KEYS = [
        "Parasha_Bereshit",    // 0
        "Parasha_Noach",       // 1
        "Parasha_LechLecha",   // 2
        "Parasha_Vayera",      // 3
        "Parasha_ChayeiSarah", // 4
        "Parasha_Toldot",      // 5
        "Parasha_Vayetzei",    // 6
        "Parasha_Vayishlach",  // 7
        "Parasha_Vayeshev",    // 8
        "Parasha_Miketz",      // 9
        "Parasha_Vayigash",    // 10
        "Parasha_Vayechi",     // 11
        "Parasha_Shemot",      // 12
        "Parasha_Vaera",       // 13
        "Parasha_Bo",          // 14
        "Parasha_Beshalach",   // 15
        "Parasha_Yitro",       // 16
        "Parasha_Mishpatim",   // 17
        "Parasha_Terumah",     // 18
        "Parasha_Tetzaveh",    // 19
        "Parasha_KiTisa",      // 20
        "Parasha_Vayakhel",    // 21
        "Parasha_Pekudei",     // 22
        "Parasha_Vayikra",     // 23
        "Parasha_Tzav",        // 24
        "Parasha_Shemini",     // 25
        "Parasha_Tazria",      // 26
        "Parasha_Metzora",     // 27
        "Parasha_AchreiMot",   // 28
        "Parasha_Kedoshim",    // 29
        "Parasha_Emor",        // 30
        "Parasha_Behar",       // 31
        "Parasha_Bechukotai",  // 32
        "Parasha_Bamidbar",    // 33
        "Parasha_Nasso",       // 34
        "Parasha_Behaalotecha",// 35
        "Parasha_Shelach",     // 36
        "Parasha_Korach",      // 37
        "Parasha_Chukat",      // 38
        "Parasha_Balak",       // 39
        "Parasha_Pinchas",     // 40
        "Parasha_Matot",       // 41
        "Parasha_Masei",       // 42
        "Parasha_Devarim",     // 43
        "Parasha_Vaetchanan",  // 44
        "Parasha_Eikev",       // 45
        "Parasha_ReEh",        // 46
        "Parasha_Shoftim",     // 47
        "Parasha_KiTeitzei",   // 48
        "Parasha_KiTavo",      // 49
        "Parasha_Nitzavim",    // 50
        "Parasha_Vayelech",    // 51
        "Parasha_Haazinu",     // 52
        "Parasha_VeZotHaBeracha" // 53
    ] as Lang.Array<Lang.String>;

    // Combined parasha index (100–106) → string key
    private static const COMBINED_STRING_KEYS = [
        "Parasha_VayakhlelPekudei",  // 100
        "Parasha_TazriaMetzora",     // 101
        "Parasha_AchreiKedoshim",    // 102
        "Parasha_BeharBechukotai",   // 103
        "Parasha_ChukatBalak",       // 104
        "Parasha_MatotMasei",        // 105
        "Parasha_NitzavimVayelech"   // 106
    ] as Lang.Array<Lang.String>;

    // Special Shabbat index (200–208) → string key
    private static const SPECIAL_STRING_KEYS = [
        "Shabbat_Shekalim",   // 200
        "Shabbat_Zachor",     // 201
        "Shabbat_Para",       // 202
        "Shabbat_Hachodesh",  // 203
        "Shabbat_Hagadol",    // 204
        "Shabbat_Chazon",     // 205
        "Shabbat_Nachamu",    // 206
        "Shabbat_Shuva",      // 207
        "Shabbat_Shira"       // 208
    ] as Lang.Array<Lang.String>;

    // 17-type parsha schedule translated from KosherJava JewishCalendar.parshalist.
    // Indexed as PARSHA_LIST[yearType][(roshHashanaDow + shabbatDayOfYear) / 7].
    // Each row has 51–56 entries covering the full Shabbat sequence in the year.
    // Integer mapping: 0–53 = regular parasha, 100–106 = combined, -1 = no reading.
    private static const PARSHA_LIST = [
        // Row 0: non-leap, Mon RH KislevShort (BaCh) — both Israel and Diaspora
        [ -1, 51, 52, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 100, 23, 24, -1, 25,
          101, 102, 30, 103, 33, 34, 35, 36, 37, 38, 39, 40, 105,
          43, 44, 45, 46, 47, 48, 49, 106 ],
        // Row 1: non-leap, Mon RH CheshvanLong or Tue RH — Diaspora
        [ -1, 51, 52, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 100, 23, 24, -1, 25,
          101, 102, 30, 103, 33, -1, 34, 35, 36, 37, 104, 40, 105,
          43, 44, 45, 46, 47, 48, 49, 106 ],
        // Row 2: non-leap, Thu RH normal (HaK) — Diaspora
        [ -1, 52, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 100, 23, 24, -1, -1,
          25, 101, 102, 30, 103, 33, 34, 35, 36, 37, 38, 39, 40, 105,
          43, 44, 45, 46, 47, 48, 49, 50 ],
        // Row 3: non-leap, Thu RH CheshvanLong (HaSh) — both
        [ -1, 52, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, -1,
          25, 101, 102, 30, 103, 33, 34, 35, 36, 37, 38, 39, 40, 105,
          43, 44, 45, 46, 47, 48, 49, 50 ],
        // Row 4: non-leap, Sat RH KislevShort (ZaCh) — both
        [ -1, -1, 52, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 100, 23, 24, -1, 25,
          101, 102, 30, 103, 33, 34, 35, 36, 37, 38, 39, 40, 105,
          43, 44, 45, 46, 47, 48, 49, 50 ],
        // Row 5: non-leap, Sat RH CheshvanLong (ZaSh) — both
        [ -1, -1, 52, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 100, 23, 24, -1, 25,
          101, 102, 30, 103, 33, 34, 35, 36, 37, 38, 39, 40, 105,
          43, 44, 45, 46, 47, 48, 49, 106 ],
        // Row 6: leap, Mon RH KislevShort (BaCh) — Diaspora
        [ -1, 51, 52, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, -1, 28, 29, 30, 31, 32, 33, -1, 34, 35, 36, 37,
          104, 40, 105, 43, 44, 45, 46, 47, 48, 49, 106 ],
        // Row 7: leap, Mon RH CheshvanLong or Tue RH — Diaspora
        [ -1, 51, 52, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, -1, -1, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37,
          38, 39, 40, 105, 43, 44, 45, 46, 47, 48, 49, 50 ],
        // Row 8: leap, Thu RH KislevShort (HaCh) — both
        [ -1, 52, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, 28, -1, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
          39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50 ],
        // Row 9: leap, Thu RH CheshvanLong (HaSh) — both
        [ -1, 52, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, 28, -1, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
          39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 106 ],
        // Row 10: leap, Sat RH KislevShort (ZaCh) — both
        [ -1, -1, 52, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, -1, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
          39, 40, 105, 43, 44, 45, 46, 47, 48, 49, 106 ],
        // Row 11: leap, Sat RH CheshvanLong (ZaSh) — Diaspora
        [ -1, -1, 52, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, -1, 28, 29, 30, 31, 32, 33, -1, 34, 35, 36, 37,
          104, 40, 105, 43, 44, 45, 46, 47, 48, 49, 106 ],
        // Row 12: non-leap, Mon RH CheshvanLong or Tue RH — Israel
        [ -1, 51, 52, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 100, 23, 24, -1, 25,
          101, 102, 30, 103, 33, 34, 35, 36, 37, 38, 39, 40, 105,
          43, 44, 45, 46, 47, 48, 49, 106 ],
        // Row 13: non-leap, Thu RH normal (HaK) — Israel
        [ -1, 52, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 100, 23, 24, -1, 25,
          101, 102, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 105,
          43, 44, 45, 46, 47, 48, 49, 50 ],
        // Row 14: leap, Mon RH KislevShort (BaCh) — Israel
        [ -1, 51, 52, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, -1, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
          39, 40, 105, 43, 44, 45, 46, 47, 48, 49, 106 ],
        // Row 15: leap, Mon RH CheshvanLong or Tue RH — Israel
        [ -1, 51, 52, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, -1, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
          39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50 ],
        // Row 16: leap, Sat RH CheshvanLong (ZaSh) — Israel
        [ -1, -1, 52, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, -1, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
          39, 40, 105, 43, 44, 45, 46, 47, 48, 49, 106 ]
    ] as Lang.Array<Lang.Array<Lang.Number>>;

    private var _cachedWeekId    as Lang.Number;
    private var _cachedIndex     as Lang.Number;
    private var _cachedSpecialIdx as Lang.Number;
    private var _cachedIsrael    as Lang.Boolean;

    function initialize() {
        _cachedWeekId     = -1;
        _cachedIndex      = -1;
        _cachedSpecialIdx = -1;
        _cachedIsrael     = false;
    }

    // Returns the parasha index for the current week's Shabbat.
    // Cached by Gregorian week; returns -1 on Yom Tov or error.
    function getParashaIndexForToday(isIsrael as Lang.Boolean) as Lang.Number {
        _ensureCached(isIsrael);
        return _cachedIndex;
    }

    // Returns the special Shabbat index for this week (200–208), or -1 if none.
    function getSpecialShabbosIndex(isIsrael as Lang.Boolean) as Lang.Number {
        _ensureCached(isIsrael);
        return _cachedSpecialIdx;
    }

    // Returns the display name for the current week's parasha (and any special
    // Shabbat annotation appended in parentheses).
    // Returns "--" when there is no regular parasha reading.
    function getParashaName(isIsrael as Lang.Boolean) as Lang.String {
        try {
            _ensureCached(isIsrael);
            var index = _cachedIndex;
            if (index < 0) {
                return "--";
            }
            var key = getParashaStringKey(index);
            if (key.equals("")) {
                return "--";
            }
            var name = WatchUi.loadResource(Rez.Strings[key]) as Lang.String;

            // Append special Shabbat label when present
            var specIdx = _cachedSpecialIdx;
            if (specIdx >= 200 && specIdx <= 208) {
                var specKey = SPECIAL_STRING_KEYS[specIdx - 200];
                var specName = WatchUi.loadResource(Rez.Strings[specKey]) as Lang.String;
                name = name + " (" + specName + ")";
            }
            return name;
        } catch (ex instanceof Lang.Exception) {
            return "--";
        }
    }

    // Returns the Rez.Strings key name for the given parasha index.
    // Combined parashiyot (100–106) return their combined key.
    // Returns "" on unknown index.
    function getParashaStringKey(index as Lang.Number) as Lang.String {
        if (index >= 0 && index < PARASHA_STRING_KEYS.size()) {
            return PARASHA_STRING_KEYS[index];
        }
        if (index >= 100 && index <= 106) {
            return COMBINED_STRING_KEYS[index - 100];
        }
        return "";
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private function _ensureCached(isIsrael as Lang.Boolean) as Void {
        var weekId = DateMath.todayDayId() / 7;
        if (weekId == _cachedWeekId && isIsrael == _cachedIsrael) {
            return;
        }
        _computeAndCache(isIsrael);
    }

    // Computes parasha index and special Shabbat index for the upcoming (or
    // current) Shabbat and stores them in instance variables.
    private function _computeAndCache(isIsrael as Lang.Boolean) as Void {
        try {
            var now      = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            // day_of_week: 1=Sun, 2=Mon, ..., 7=Sat
            var todayDow = now.day_of_week;
            // Days until the next (or current) Shabbat
            var daysUntilShabbat = (7 - todayDow) % 7; // 0 if today is Sat

            var hyear = HebrewCalendarService.todayHebrewYear();
            var doy   = HebrewCalendarService.todayHebrewDayOfYear();

            // Hebrew day-of-year for the relevant Shabbat
            var shabbatDoy = doy + daysUntilShabbat;
            var checkYear  = hyear;
            if (shabbatDoy > HebrewCalendarService.daysInHebrewYear(hyear)) {
                shabbatDoy -= HebrewCalendarService.daysInHebrewYear(hyear);
                checkYear   = hyear + 1;
            }

            var yearType = _parshaYearType(checkYear, isIsrael);
            if (yearType < 0) {
                _cachedIndex      = -1;
                _cachedSpecialIdx = -1;
                _cachedWeekId     = DateMath.todayDayId() / 7;
                _cachedIsrael     = isIsrael;
                return;
            }

            // KosherJava table index: (elapsedDays % 7) + shabbatDayOfYear
            var roshHashanaDow = (HebrewCalendarService.elapsedDaysHebrewYear(checkYear) % 7l) as Lang.Number;
            var tableIndex     = (roshHashanaDow + shabbatDoy) / 7;

            var schedule = PARSHA_LIST[yearType] as Lang.Array<Lang.Number>;
            _cachedIndex = (tableIndex >= 0 && tableIndex < schedule.size())
                ? (schedule[tableIndex] as Lang.Number)
                : -1;

            _cachedSpecialIdx = _specialShabbosForShabbat(checkYear, shabbatDoy, _cachedIndex);

            _cachedWeekId  = DateMath.todayDayId() / 7;
            _cachedIsrael  = isIsrael;
        } catch (ex instanceof Lang.Exception) {
            _cachedIndex      = -1;
            _cachedSpecialIdx = -1;
        }
    }

    // Determine the parsha year type (0–16) matching KosherJava getParshaYearType().
    // Uses roshHashanaDayOfWeek() which returns 2=Mon, 3=Tue, 5=Thu, 7=Sat
    // (Java Calendar scale, matching the constants used in KosherJava's switch-cases).
    private function _parshaYearType(year as Lang.Number, isIsrael as Lang.Boolean) as Lang.Number {
        var dow    = HebrewCalendarService.roshHashanaDayOfWeek(year);
        var isLeap = HebrewCalendarService.isHebrewLeapYear(year);
        var chLong = HebrewCalendarService.isCheshvanLong(year);
        var kiShort = HebrewCalendarService.isKislevShort(year);

        if (isLeap) {
            if (dow == 2) { // Monday
                if (kiShort)  { return isIsrael ? 14 : 6; }
                if (chLong)   { return isIsrael ? 15 : 7; }
            } else if (dow == 3) { // Tuesday
                return isIsrael ? 15 : 7;
            } else if (dow == 5) { // Thursday
                if (kiShort)  { return 8; }
                if (chLong)   { return 9; }
            } else if (dow == 7) { // Saturday
                if (kiShort)  { return 10; }
                if (chLong)   { return isIsrael ? 16 : 11; }
            }
        } else {
            if (dow == 2) { // Monday
                if (kiShort)  { return 0; }
                if (chLong)   { return isIsrael ? 12 : 1; }
            } else if (dow == 3) { // Tuesday
                return isIsrael ? 12 : 1;
            } else if (dow == 5) { // Thursday
                if (chLong)   { return 3; }
                if (!kiShort) { return isIsrael ? 13 : 2; }
            } else if (dow == 7) { // Saturday
                if (kiShort)  { return 4; }
                if (chLong)   { return 5; }
            }
        }
        return -1;
    }

    // Ports KosherJava JewishCalendar.getSpecialShabbos() to determine the
    // special Shabbat designation for a given Shabbat in the Hebrew year.
    //
    // Month numbers are 1-based from Tishrei (our internal convention):
    //   1=Tishrei, 2=Cheshvan, 3=Kislev, 4=Tevet, 5=Shevat,
    //   6=Adar(non-leap)/Adar-I(leap), 7=Nissan(non-leap)/Adar-II(leap),
    //   8=Iyar(non-leap)/Nissan(leap), ...
    //
    // Returns 200–208 for a special Shabbat, or -1 if none.
    private function _specialShabbosForShabbat(
        year        as Lang.Number,
        shabbatDoy  as Lang.Number,
        parashaIndex as Lang.Number
    ) as Lang.Number {
        var isLeap = HebrewCalendarService.isHebrewLeapYear(year);
        var month  = HebrewCalendarService.hebrewMonthForDayOfYear(year, shabbatDoy);
        var day    = HebrewCalendarService.hebrewDayOfMonthForDayOfYear(year, shabbatDoy);

        // Shabbat Shira: when Beshalach (index 15) is the parasha of the week
        if (parashaIndex == 15) { return 208; }

        // Shabbat Shekalim (first of the Arba Parashiyot)
        // KJ: (SHEVAT && !leap) || (ADAR && leap) at days 25, 27, or 29
        // Ours: (month==5 && !leap) || (month==6 && leap)
        if ((month == 5 && !isLeap) || (month == 6 && isLeap)) {
            if (day == 25 || day == 27 || day == 29) { return 200; }
        }

        // The "final Adar" before Nissan:
        //   non-leap: month 6 (Adar);  leap: month 7 (Adar II)
        var isFinalAdar = (month == 6 && !isLeap) || (month == 7 && isLeap);
        if (isFinalAdar) {
            if (day == 1)  { return 200; } // Shekalim (1 Adar/Adar-II)
            if (day == 8 || day == 9 || day == 11 || day == 13) { return 201; } // Zachor
            if (day == 18 || day == 20 || day == 22 || day == 23) { return 202; } // Para
            if (day == 25 || day == 27 || day == 29) { return 203; } // Hachodesh
        }

        // Nissan: month 7 (non-leap) or month 8 (leap)
        var nissanMonth = isLeap ? 8 : 7;
        if (month == nissanMonth) {
            if (day == 1) { return 203; } // Shabbat Hachodesh (1 Nissan)
            if (day >= 8 && day <= 14) { return 204; } // Shabbat Hagadol
        }

        // Av: month 11 (non-leap) or month 12 (leap)
        var avMonth = isLeap ? 12 : 11;
        if (month == avMonth) {
            if (day >= 4 && day <= 9)   { return 205; } // Shabbat Chazon
            if (day >= 10 && day <= 16) { return 206; } // Shabbat Nachamu
        }

        // Tishrei: month 1
        if (month == 1) {
            if (day >= 3 && day <= 8) { return 207; } // Shabbat Shuva
        }

        return -1;
    }
}
