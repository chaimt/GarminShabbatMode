using Toybox.Lang;
using Toybox.WatchUi;

// Determines the current week's Parashat HaShavua (weekly Torah portion)
// based on the Hebrew calendar date computed by HebrewCalendarService.
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
// Reference: KosherJava JewishCalendar.getParashahIndex() and
// Calendrical Calculations §8.
//
// Each schedule array has 55 entries (weeks 0–54 of the Hebrew year).
// Week 0 starts on 1 Tishrei (Rosh Hashana).  Week index = (dayOfYear - 1) / 7.
//
// Schedule arrays are indexed by year-type code:
//   0 = deficient regular  (353 days, type 1, non-leap)
//   1 = regular regular    (354 days, type 2, non-leap)
//   2 = complete regular   (355 days, type 3, non-leap)
//   3 = deficient leap     (383 days, type 1, leap)
//   4 = regular leap       (384 days, type 2, leap)
//   5 = complete leap      (385 days, type 3, leap)
class ParashaService {

    // Parasha index → Rez.Strings key name (string, loaded at runtime).
    // Index matches the order in parasha_strings.xml.
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

    // Combined parasha index (100+) → string key
    private static const COMBINED_STRING_KEYS = [
        "Parasha_VayakhlelPekudei",  // 100
        "Parasha_TazriaMetzora",     // 101
        "Parasha_AchreiKedoshim",    // 102
        "Parasha_BeharBechukotai",   // 103
        "Parasha_ChukatBalak",       // 104
        "Parasha_MatotMasei",        // 105
        "Parasha_NitzavimVayelech"   // 106
    ] as Lang.Array<Lang.String>;

    // Parasha schedule for each Hebrew year type (Diaspora).
    // 55 entries per year type; index = (hebrewDayOfYear - 1) / 7
    // Values: 0–53 = single parasha, 100–106 = combined, -1 = holiday week
    //
    // Week 0 = Rosh Hashana (Bereshit read ~week 3-4 after RH).
    // This table is derived from the standard parasha cycle documented in
    // KosherJava JewishCalendar and Calendrical Calculations §8.
    //
    // Format: [weekIndex] = parashaIndex
    // Weeks where Yom Tov falls get -1 (no regular Shabbat parasha reading).
    private static const DIASPORA_SCHEDULE = [
        // Type 0: deficient regular (353 days) — Mon or Sat RH
        [ -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 100, 23, 24, 25,
          101, 102, 30, 103, 33, 34, 35, 36, 37, 38, 39, 40, 41,
          105, 43, 44, 45, 46, 47, 48, 49, 106, 52, 53, -1, -1, -1, -1 ],
        // Type 1: regular regular (354 days) — Mon or Sat RH
        [ -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          101, 102, 30, 103, 33, 34, 35, 36, 37, 38, 39, 40, 105,
          43, 44, 45, 46, 47, 48, 49, 106, 52, 53, -1, -1, -1, -1 ],
        // Type 2: complete regular (355 days) — Tue or Thu RH
        [ -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, 28, 29, 30, 103, 33, 34, 35, 36, 37, 38, 39, 40,
          105, 43, 44, 45, 46, 47, 48, 49, 106, 52, 53, -1, -1, -1 ],
        // Type 3: deficient leap (383 days)
        [ -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
          40, 105, 43, 44, 45, 46, 47, 48, 49, 106, 52, 53, -1, -1 ],
        // Type 4: regular leap (384 days)
        [ -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
          40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 106, 52, 53, -1, -1 ],
        // Type 5: complete leap (385 days)
        [ -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
          40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, -1 ]
    ] as Lang.Array<Lang.Array<Lang.Number>>;

    // Israel schedule — differs from Diaspora in weeks after Pesach in some years.
    // In Israel, Yom Tov is only 1 day (not 2), so the split resolves 1 week earlier.
    // The Diaspora reads a combined parasha (e.g., Achrei-Kedoshim) while Israel
    // reads them separately in weeks prior, then syncs back later in the year.
    //
    // For simplicity, the Israel schedule matches the Diaspora schedule except
    // for year types 0–2 (non-leap) where the post-Pesach combined parashiyot
    // are separated:
    private static const ISRAEL_SCHEDULE = [
        // Type 0: deficient regular — Israel
        [ -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 100, 23, 24, 25,
          26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
          105, 43, 44, 45, 46, 47, 48, 49, 106, 52, 53, -1, -1, -1 ],
        // Type 1: regular regular — Israel
        [ -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
          105, 43, 44, 45, 46, 47, 48, 49, 106, 52, 53, -1, -1 ],
        // Type 2: complete regular — Israel
        [ -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
          41, 42, 43, 44, 45, 46, 47, 48, 49, 106, 52, 53, -1, -1 ],
        // Types 3–5 (leap years): same as Diaspora
        [ -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
          40, 105, 43, 44, 45, 46, 47, 48, 49, 106, 52, 53, -1, -1 ],
        [ -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
          40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 106, 52, 53, -1, -1 ],
        [ -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
          12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
          26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
          40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, -1 ]
    ] as Lang.Array<Lang.Array<Lang.Number>>;

    private var _cachedWeekId  as Lang.Number;
    private var _cachedIndex   as Lang.Number;
    private var _cachedIsrael  as Lang.Boolean;

    function initialize() {
        _cachedWeekId = -1;
        _cachedIndex  = -1;
        _cachedIsrael = false;
    }

    // Returns the parasha index for the current week.
    // Cached by week (recomputed at most once per 7 days).
    function getParashaIndexForToday(isIsrael as Lang.Boolean) as Lang.Number {
        var weekId = DateMath.todayDayId() / 7;
        if (weekId == _cachedWeekId && isIsrael == _cachedIsrael) {
            return _cachedIndex;
        }

        try {
            var hyear   = HebrewCalendarService.todayHebrewYear();
            var dayOfYear = HebrewCalendarService.todayHebrewDayOfYear();
            var weekIndex = (dayOfYear - 1) / 7;

            var typeCode = _yearTypeCode(hyear);
            var schedule = isIsrael
                ? (ISRAEL_SCHEDULE[typeCode] as Lang.Array<Lang.Number>)
                : (DIASPORA_SCHEDULE[typeCode] as Lang.Array<Lang.Number>);

            var index = -1;
            if (weekIndex >= 0 && weekIndex < schedule.size()) {
                index = schedule[weekIndex];
            }

            _cachedWeekId = weekId;
            _cachedIndex  = index;
            _cachedIsrael = isIsrael;
            return index;
        } catch (ex instanceof Lang.Exception) {
            return -1;
        }
    }

    // Returns the display name for the given parasha index.
    // Returns "--" when index is -1 (Yom Tov) or on error.
    function getParashaName(isIsrael as Lang.Boolean) as Lang.String {
        try {
            var index = getParashaIndexForToday(isIsrael);
            if (index < 0) {
                return "--";
            }
            var key = getParashaStringKey(index);
            if (key.equals("")) {
                return "--";
            }
            return WatchUi.loadResource(Rez.Strings[key]) as Lang.String;
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

    // Map Hebrew year to schedule array index (0–5).
    private function _yearTypeCode(year as Lang.Number) as Lang.Number {
        var isLeap = HebrewCalendarService.isHebrewLeapYear(year);
        var type   = HebrewCalendarService.hebrewYearType(year);   // 1, 2, or 3
        if (!isLeap) {
            return type - 1;   // 0, 1, 2
        }
        return type + 2;       // 3, 4, 5
    }
}
