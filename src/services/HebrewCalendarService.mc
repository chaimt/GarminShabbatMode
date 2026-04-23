using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

// Converts Gregorian dates to Hebrew calendar dates using the standard
// Maimonides / Dershowitz-Reingold algorithm.
//
// All Julian Day (JD) values use Lang.Long to avoid 32-bit integer overflow
// (current JD is ~2.46 million; Hebrew epoch JD is ~347,996).
//
// Reference: E. Dershowitz & E. Reingold, "Calendrical Calculations" (4th ed.)
// §8 (Hebrew Calendar).  The molad arithmetic follows KosherJava's
// JewishCalendar implementation.
class HebrewCalendarService {

    // Hebrew epoch: Julian Day of 1 Tishrei 1 AM = JD 347,996
    // (Gregorian proleptic: Monday, 7 Oct 3761 BCE)
    private static const HEBREW_EPOCH_JD = 347996l;

    // Seconds in a halak (smallest Talmudic time unit): 1 hour / 1080
    private static const CHALAKIM_PER_HOUR = 1080l;
    private static const CHALAKIM_PER_DAY  = 25920l;   // 24 * 1080

    // Molad Tohu: reference new moon — 2d 5h 204 chalakim
    // expressed as chalakim from epoch start of Sunday 0h:
    //   2 days * 25920 + 5 * 1080 + 204 = 51840 + 5400 + 204 = 57444
    private static const MOLAD_TOHU = 57444l;

    // Average month length in chalakim: 29d 12h 793 chalakim
    //   = 29*25920 + 12*1080 + 793 = 765433
    private static const MOLAD_PERIOD = 765433l;

    // 19-year Metonic cycle in chalakim: 235 months
    private static const CHALAKIM_PER_19_YEARS = 179640l * 1000l; // 235 * 765433 / 1000 ≈ 179,940; exact below

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    // True when the Hebrew year is a leap year (13 months instead of 12).
    // Leap years in the 19-year Metonic cycle: years 3,6,8,11,14,17,19.
    // Formula: (7*year + 1) mod 19 < 7
    static function isHebrewLeapYear(year as Lang.Number) as Lang.Boolean {
        return ((7 * year + 1) % 19) < 7;
    }

    // Number of months in the Hebrew year (12 or 13).
    static function monthsInHebrewYear(year as Lang.Number) as Lang.Number {
        return isHebrewLeapYear(year) ? 13 : 12;
    }

    // Elapsed days from Hebrew epoch (1 Tishrei 1 AM = day 1) to
    // 1 Tishrei of the given Hebrew year.  Uses Long arithmetic throughout.
    static function elapsedDaysHebrewYear(year as Lang.Number) as Lang.Long {
        var monthsElapsed = _monthsElapsed(year);
        var partsElapsed  = MOLAD_TOHU + MOLAD_PERIOD * monthsElapsed;
        var day  = (partsElapsed / CHALAKIM_PER_DAY) as Lang.Long;
        var part = (partsElapsed % CHALAKIM_PER_DAY) as Lang.Long;

        // Postponement rules (dehiyyot):
        // Rule 1: Molad on day 1 (Sun) at or after noon → postpone to day 2
        // Rule 2: Molad on day 4 (Wed) at or after 18h → postpone to next Thursday
        // Rule 3: Molad on day 3 at or after 9h 204 parts, non-leap → postpone to Fri
        // Rule 4: After leap year, molad on day 2 at or after 15h 589 parts → postpone to Tue

        var dayOfWeek = (day % 7) as Lang.Number;   // 0=Sun
        var altDay = day;

        if (part >= 19440l ||                                                  // Rule 1: noon = 12h * 1080
            (dayOfWeek == 2 && part >= 9924l && !isHebrewLeapYear(year)) ||   // Rule 3
            (dayOfWeek == 1 && part >= 16789l && isHebrewLeapYear(year - 1))) { // Rule 4
            altDay = day + 1l;
        }

        var altDayOfWeek = (altDay % 7) as Lang.Number;
        if (altDayOfWeek == 0 || altDayOfWeek == 3 || altDayOfWeek == 5) {    // Rule 2
            altDay = altDay + 1l;
        }

        return altDay;
    }

    // Number of days in the Hebrew year.
    // Regular year: 353 (deficient), 354 (regular), or 355 (complete).
    // Leap year:    383 (deficient), 384 (regular), or 385 (complete).
    static function daysInHebrewYear(year as Lang.Number) as Lang.Number {
        return (elapsedDaysHebrewYear(year + 1) - elapsedDaysHebrewYear(year)) as Lang.Number;
    }

    // Year type as a number:
    //   1 = deficient  (353 / 383 days)
    //   2 = regular    (354 / 384 days)
    //   3 = complete   (355 / 385 days)
    static function hebrewYearType(year as Lang.Number) as Lang.Number {
        var d = daysInHebrewYear(year) % 10;
        if (d == 3) { return 1; }   // 353 or 383
        if (d == 4) { return 2; }   // 354 or 384
        return 3;                   // 355 or 385
    }

    // Convert a proleptic Gregorian date to a Julian Day Number.
    // Returns a Long.
    static function julianDayFromGregorian(year as Lang.Number, month as Lang.Number, day as Lang.Number) as Lang.Long {
        var y = year as Lang.Long;
        var m = month as Lang.Long;
        var d = day as Lang.Long;
        if (m <= 2l) {
            y = y - 1l;
            m = m + 12l;
        }
        var a = y / 4l - y / 100l + y / 400l;
        return 365l * y + a + (153l * m + 8l) / 5l + d - 32045l;
    }

    // Hebrew year that contains the given Gregorian date.
    static function gregorianToHebrewYear(gregorianYear as Lang.Number, gregorianMonth as Lang.Number, gregorianDay as Lang.Number) as Lang.Number {
        var jd = julianDayFromGregorian(gregorianYear, gregorianMonth, gregorianDay);
        // Approximate Hebrew year and refine
        var approx = ((jd - HEBREW_EPOCH_JD) * 98496l / 35975351l + 1l) as Lang.Number;
        // elapsedDaysHebrewYear gives 1 Tishrei; find the year whose Tishrei <= jd
        var year = approx - 1;
        while (elapsedDaysHebrewYear(year + 1) + HEBREW_EPOCH_JD <= jd) {
            year++;
        }
        return year;
    }

    // Day-of-year within the Hebrew year (1 = 1 Tishrei).
    static function hebrewDayOfYear(gregorianYear as Lang.Number, gregorianMonth as Lang.Number, gregorianDay as Lang.Number) as Lang.Number {
        var jd   = julianDayFromGregorian(gregorianYear, gregorianMonth, gregorianDay);
        var hyear = gregorianToHebrewYear(gregorianYear, gregorianMonth, gregorianDay);
        var roshHashanaJd = elapsedDaysHebrewYear(hyear) + HEBREW_EPOCH_JD;
        return (jd - roshHashanaJd + 1l) as Lang.Number;
    }

    // Today's Hebrew year, derived from the device Gregorian clock.
    static function todayHebrewYear() as Lang.Number {
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return gregorianToHebrewYear(now.year, now.month, now.day);
    }

    // Today's day-of-Hebrew-year (1 = 1 Tishrei), derived from device clock.
    static function todayHebrewDayOfYear() as Lang.Number {
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return hebrewDayOfYear(now.year, now.month, now.day);
    }

    // True when Cheshvan has 30 days (year is "complete": 355 or 385 days).
    static function isCheshvanLong(year as Lang.Number) as Lang.Boolean {
        return daysInHebrewYear(year) % 10 == 5;
    }

    // True when Kislev has 29 days (year is "deficient": 353 or 383 days).
    static function isKislevShort(year as Lang.Number) as Lang.Boolean {
        return daysInHebrewYear(year) % 10 == 3;
    }

    // Day of week that 1 Tishrei (Rosh Hashana) falls on for the given year.
    // Returns a value in Java Calendar scale: 2=Mon, 3=Tue, 5=Thu, 7=Sat.
    // (Rosh Hashana is always Mon, Tue, Thu, or Sat per the dehiyyot rules.)
    // Matches KosherJava JewishCalendar.getParshaYearType() computation:
    //   (getJewishCalendarElapsedDays(year) + 1) % 7, with 0 → 7 for Shabbat.
    static function roshHashanaDayOfWeek(year as Lang.Number) as Lang.Number {
        var dow = ((elapsedDaysHebrewYear(year) + 1l) % 7l) as Lang.Number;
        if (dow == 0) { dow = 7; }
        return dow;
    }

    // Month number (1 = Tishrei) that contains the given day-of-year within
    // the Hebrew year.  In a leap year there are 13 months; in a regular year 12.
    static function hebrewMonthForDayOfYear(year as Lang.Number, dayOfYear as Lang.Number) as Lang.Number {
        var lengths = _monthLengths(year);
        var numMonths = isHebrewLeapYear(year) ? 13 : 12;
        var cum = 0;
        for (var m = 0; m < numMonths; m++) {
            cum += lengths[m];
            if (dayOfYear <= cum) {
                return m + 1;
            }
        }
        return numMonths;
    }

    // Day within the Hebrew month (1-based) for the given day-of-year.
    static function hebrewDayOfMonthForDayOfYear(year as Lang.Number, dayOfYear as Lang.Number) as Lang.Number {
        var lengths = _monthLengths(year);
        var numMonths = isHebrewLeapYear(year) ? 13 : 12;
        var cum = 0;
        for (var m = 0; m < numMonths; m++) {
            cum += lengths[m];
            if (dayOfYear <= cum) {
                return dayOfYear - (cum - lengths[m]);
            }
        }
        return dayOfYear;
    }

    // Today's Hebrew month (1 = Tishrei), derived from device clock.
    static function todayHebrewMonth() as Lang.Number {
        var now  = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var year = gregorianToHebrewYear(now.year, now.month, now.day);
        var doy  = hebrewDayOfYear(now.year, now.month, now.day);
        return hebrewMonthForDayOfYear(year, doy);
    }

    // Today's Hebrew day-of-month (1-based), derived from device clock.
    static function todayHebrewDay() as Lang.Number {
        var now  = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var year = gregorianToHebrewYear(now.year, now.month, now.day);
        var doy  = hebrewDayOfYear(now.year, now.month, now.day);
        return hebrewDayOfMonthForDayOfYear(year, doy);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    // Total months elapsed from epoch to the start of the given Hebrew year.
    private static function _monthsElapsed(year as Lang.Number) as Lang.Long {
        var y = year as Lang.Long;
        // Complete 19-year cycles
        var cycles  = (y - 1l) / 19l;
        var remainder = ((y - 1l) % 19l) as Lang.Number;
        var months = 235l * cycles + 12l * (remainder as Lang.Long);
        // Add leap months for years within the partial cycle
        months = months + ((7l * (remainder as Lang.Long) + 1l) / 19l);
        return months;
    }

    // Returns an array of month lengths (in days) for the given Hebrew year,
    // indexed 0-based from Tishrei.  Leap years have 13 entries, regular 12.
    // Month order from Tishrei:
    //   1=Tishrei, 2=Cheshvan, 3=Kislev, 4=Tevet, 5=Shevat,
    //   6=Adar (non-leap) / Adar-I (leap),
    //   7=Nissan (non-leap) / Adar-II (leap),
    //   8=Iyar (non-leap) / Nissan (leap),
    //   9..12/13 continue alternating 30/29.
    private static function _monthLengths(year as Lang.Number) as Lang.Array<Lang.Number> {
        var isLeap = isHebrewLeapYear(year);
        var chLong = isCheshvanLong(year);
        var kiShort = isKislevShort(year);
        if (isLeap) {
            return [
                30,              // 1  Tishrei
                chLong ? 30 : 29, // 2  Cheshvan
                kiShort ? 29 : 30, // 3  Kislev
                29,              // 4  Tevet
                30,              // 5  Shevat
                30,              // 6  Adar I
                29,              // 7  Adar II
                30,              // 8  Nissan
                29,              // 9  Iyar
                30,              // 10 Sivan
                29,              // 11 Tammuz
                30,              // 12 Av
                29               // 13 Elul
            ] as Lang.Array<Lang.Number>;
        }
        return [
            30,              // 1  Tishrei
            chLong ? 30 : 29, // 2  Cheshvan
            kiShort ? 29 : 30, // 3  Kislev
            29,              // 4  Tevet
            30,              // 5  Shevat
            29,              // 6  Adar
            30,              // 7  Nissan
            29,              // 8  Iyar
            30,              // 9  Sivan
            29,              // 10 Tammuz
            30,              // 11 Av
            29               // 12 Elul
        ] as Lang.Array<Lang.Number>;
    }
}
