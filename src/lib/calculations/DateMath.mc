using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

// Date and time mathematical utilities for astronomical calculations.
class DateMath {

    // Seconds per unit constants
    static const SECONDS_PER_MINUTE = 60;
    static const SECONDS_PER_HOUR   = 3600;
    static const SECONDS_PER_DAY    = 86400;
    static const MINUTES_PER_HOUR   = 60;
    static const MINUTES_PER_DAY    = 1440;

    // Garmin epoch offset relative to J2000.0 (Jan 1, 2000 12:00 UTC).
    // Garmin epoch = Jan 1, 1990 00:00 UTC.
    // Difference   = 3652.5 days * 86400 s/day = 315 576 000 s.
    static const GARMIN_TO_J2000_OFFSET_S = 315576000;

    // Return Julian day number (JDN) from a Gregorian calendar date.
    // Algorithm: https://en.wikipedia.org/wiki/Julian_day#Converting_Gregorian_calendar_date_to_Julian_Day_Number
    static function julianDayNumber(year as Lang.Number, month as Lang.Number, day as Lang.Number) as Lang.Number {
        var a = (14 - month) / 12;
        var y = year + 4800 - a;
        var m = month + 12 * a - 3;
        return day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045;
    }

    // Days since J2000.0 (Jan 1, 2000 12:00 UTC) from a Garmin epoch value.
    static function nFromGarminEpoch(garminEpochSeconds as Lang.Number) as Lang.Float {
        return (garminEpochSeconds - GARMIN_TO_J2000_OFFSET_S).toFloat() / SECONDS_PER_DAY.toFloat();
    }

    // Days since J2000.0 from Gregorian date (noon).
    static function nFromDate(year as Lang.Number, month as Lang.Number, day as Lang.Number) as Lang.Float {
        var jdn = julianDayNumber(year, month, day);
        // J2000.0 = JDN 2451545.0
        return (jdn - 2451545).toFloat();
    }

    // Construct a compact day-id integer: year * 10000 + month * 100 + day.
    static function dayId(year as Lang.Number, month as Lang.Number, day as Lang.Number) as Lang.Number {
        return year * 10000 + month * 100 + day;
    }

    // Day-id for today from device clock.
    static function todayDayId() as Lang.Number {
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        return dayId(info.year, info.month, info.day);
    }

    // Garmin epoch value for the start of today (UTC midnight).
    static function todayGarminEpoch() as Lang.Number {
        return Time.now().value();
    }

    // Normalise a seconds value into [0, 86400).
    static function normaliseDay(seconds as Lang.Number) as Lang.Number {
        var s = seconds;
        while (s < 0)          { s += SECONDS_PER_DAY; }
        while (s >= SECONDS_PER_DAY) { s -= SECONDS_PER_DAY; }
        return s;
    }

    // Add a signed minute offset to local seconds-from-midnight, wrapping.
    static function addMinutesToLocalSeconds(localSecs as Lang.Number, minutes as Lang.Number) as Lang.Number {
        return normaliseDay(localSecs + minutes * SECONDS_PER_MINUTE);
    }

    // Day of week from Gregorian.Info (1=Sun, 2=Mon, ... 7=Sat).
    static function dayOfWeekToday() as Lang.Number {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return info.day_of_week;
    }

    // Days remaining until the next occurrence of target DOW (1-7).
    static function daysUntilDow(targetDow as Lang.Number) as Lang.Number {
        var today = dayOfWeekToday();
        var diff = targetDow - today;
        if (diff <= 0) { diff += 7; }
        return diff;
    }
}
