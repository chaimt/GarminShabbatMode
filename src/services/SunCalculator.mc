using Toybox.Lang;
using Toybox.Math;

// Garmin epoch = Jan 1, 1990, 00:00:00 UTC
// J2000.0    = Jan 1, 2000, 12:00:00 UTC
// Difference = 3652.5 days * 86400 s/day = 315,576,000 seconds
const SOLAR_J2000_GARMIN_OFFSET = 315576000;

// Solar zenith angle constants — KosherJava: AstronomicalCalendar.*_ZENITH
// Zenith is measured from vertical: 90° = horizon, values > 90° are below horizon.
// Standard sunrise/sunset uses GEOMETRIC_ZENITH + 0.8333 (solar radius + refraction).
const GEOMETRIC_ZENITH    = 90.0f;   // KosherJava: AstronomicalCalendar.GEOMETRIC_ZENITH
const CIVIL_ZENITH        = 96.0f;   // KosherJava: AstronomicalCalendar.CIVIL_ZENITH
const NAUTICAL_ZENITH     = 102.0f;  // KosherJava: AstronomicalCalendar.NAUTICAL_ZENITH
const ASTRONOMICAL_ZENITH = 108.0f;  // KosherJava: AstronomicalCalendar.ASTRONOMICAL_ZENITH

// Implements the NOAA simplified solar position algorithm, matching KosherJava's
// NOAACalculator (https://kosherjava.com/zmanim-project/).
// Accuracy: approximately ±1–2 minutes at typical latitudes (23°N–60°N).
class SunCalculator {

    // Compute n (days since J2000.0) from a Garmin epoch value (seconds since Jan 1, 1990 UTC).
    static function nFromGarminEpoch(garminEpochSeconds as Lang.Number) as Lang.Float {
        return (garminEpochSeconds - SOLAR_J2000_GARMIN_OFFSET).toFloat() / 86400.0;
    }

    // Calculate standard sunset (sun centre at 0.8333° below horizon) in seconds since midnight UTC.
    // Retained for backward compatibility — delegates to calculateSunsetAtZenithUTC.
    static function calculateSunsetUTC(lat as Lang.Float, lon as Lang.Float, n as Lang.Float) as Lang.Number? {
        return calculateSunsetAtZenithUTC(lat, lon, n, GEOMETRIC_ZENITH + 0.8333f);
    }

    // Calculate the time when the sun reaches a given zenith angle after solar noon (sunset direction).
    //
    // zenithDegrees: degrees from vertical (90° = horizon; 90.8333° = standard sunset;
    //   98.5° = 8.5° below horizon = KosherJava getTzaisGeonim8Point5Degrees();
    //   97.083° = KosherJava getTzaisGeonim7Point083Degrees())
    //
    // Returns seconds from midnight UTC (0–86399), or null for polar regions.
    // KosherJava equivalent: NOAACalculator / getSunsetOffsetByDegrees(zenith)
    //
    // KosherJava reference (Lakewood NJ 40.096°N 74.222°W):
    //   2026-04-22: standard sunset ~23:27 UTC (19:27 EDT), tzais 8.5° ~00:10 UTC (+43 min)
    //   2025-12-21: standard sunset ~21:19 UTC (16:19 EST), tzais 8.5° ~22:01 UTC (+42 min)
    static function calculateSunsetAtZenithUTC(lat as Lang.Float, lon as Lang.Float, n as Lang.Float, zenithDegrees as Lang.Float) as Lang.Number? {
        var pos = _computeSolarPosition(n);
        var delta  = pos.get(:delta)  as Lang.Float;
        var eqTime = pos.get(:eqTime) as Lang.Float;

        var latRad = Math.toRadians(lat);
        // Altitude = 90° - zenith; below horizon when zenith > 90°
        var cosH = (Math.sin(Math.toRadians(90.0 - zenithDegrees))
                    - Math.sin(latRad) * Math.sin(delta))
                 / (Math.cos(latRad) * Math.cos(delta));

        if (cosH > 1.0 || cosH < -1.0) {
            return null; // Polar: midnight sun or polar night
        }

        var H = Math.toDegrees(Math.acos(cosH));
        var solarNoon = 720.0 - 4.0 * lon - eqTime;
        var sunsetMinutes = solarNoon + 4.0 * H;
        sunsetMinutes = sunsetMinutes - Math.floor(sunsetMinutes / 1440.0) * 1440.0;
        return (sunsetMinutes * 60.0).toNumber();
    }

    // Calculate the time when the sun reaches a given zenith angle before solar noon (sunrise direction).
    //
    // zenithDegrees: same convention as calculateSunsetAtZenithUTC.
    // Returns seconds from midnight UTC (0–86399), or null for polar regions.
    // KosherJava equivalent: NOAACalculator / getSunriseOffsetByDegrees(zenith)
    //
    // KosherJava reference (Lakewood NJ 40.096°N 74.222°W):
    //   2026-04-22: standard sunrise ~09:47 UTC (05:47 EDT)
    //   2025-12-21: standard sunrise ~12:08 UTC (07:08 EST)
    static function calculateSunriseAtZenithUTC(lat as Lang.Float, lon as Lang.Float, n as Lang.Float, zenithDegrees as Lang.Float) as Lang.Number? {
        var pos = _computeSolarPosition(n);
        var delta  = pos.get(:delta)  as Lang.Float;
        var eqTime = pos.get(:eqTime) as Lang.Float;

        var latRad = Math.toRadians(lat);
        var cosH = (Math.sin(Math.toRadians(90.0 - zenithDegrees))
                    - Math.sin(latRad) * Math.sin(delta))
                 / (Math.cos(latRad) * Math.cos(delta));

        if (cosH > 1.0 || cosH < -1.0) {
            return null;
        }

        var H = Math.toDegrees(Math.acos(cosH));
        var solarNoon = 720.0 - 4.0 * lon - eqTime;
        var sunriseMinutes = solarNoon - 4.0 * H; // subtract H: before noon
        sunriseMinutes = sunriseMinutes - Math.floor(sunriseMinutes / 1440.0) * 1440.0;
        return (sunriseMinutes * 60.0).toNumber();
    }

    // Calculate end-of-Shabbat (tzais) as local seconds from midnight.
    //
    // method: "degrees_8_5"  → KosherJava getTzaisGeonim8Point5Degrees()  (zenith 98.5°)
    //         "degrees_7_083"→ KosherJava getTzaisGeonim7Point083Degrees() (zenith 97.083°)
    //         "fixed_minutes"→ standard sunset + fixedOffsetMinutes (KosherJava getTzais())
    //
    // Returns local seconds from midnight (0–86399), or -1 on polar/unavailable.
    static function calculateTzaisLocalSeconds(
        lat              as Lang.Float,
        lon              as Lang.Float,
        n                as Lang.Float,
        utcOffsetSecs    as Lang.Number,
        method           as Lang.String,
        fixedOffsetMinutes as Lang.Number
    ) as Lang.Number {
        if (method.equals("degrees_8_5")) {
            var utcSecs = calculateSunsetAtZenithUTC(lat, lon, n, 98.5f);
            if (utcSecs == null) { return -1; }
            return _normaliseDay((utcSecs as Lang.Number) + utcOffsetSecs);
        }
        if (method.equals("degrees_7_083")) {
            var utcSecs = calculateSunsetAtZenithUTC(lat, lon, n, 97.083f);
            if (utcSecs == null) { return -1; }
            return _normaliseDay((utcSecs as Lang.Number) + utcOffsetSecs);
        }
        // Default: fixed_minutes — standard sunset + offset
        var sunsetUtc = calculateSunsetAtZenithUTC(lat, lon, n, GEOMETRIC_ZENITH + 0.8333f);
        if (sunsetUtc == null) { return -1; }
        return _normaliseDay((sunsetUtc as Lang.Number) + utcOffsetSecs + fixedOffsetMinutes * 60);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    // Compute solar position intermediates shared by sunrise and sunset calculations.
    // Returns {:delta => solar_declination_radians, :eqTime => equation_of_time_minutes}.
    // Eliminates the duplicated NOAA block that existed in AstronomicalService.
    static function _computeSolarPosition(n as Lang.Float) as Lang.Dictionary {
        var t = n / 36525.0;

        var L0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
        L0 = L0 - Math.floor(L0 / 360.0) * 360.0;

        var M = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
        M = M - Math.floor(M / 360.0) * 360.0;
        var Mrad = Math.toRadians(M);

        var C = (1.914602 - 0.004817 * t - 0.000014 * t * t) * Math.sin(Mrad)
              + (0.019993 - 0.000101 * t) * Math.sin(2.0 * Mrad)
              + 0.000289 * Math.sin(3.0 * Mrad);

        var sunLon   = L0 + C;
        var omegaRad = Math.toRadians(125.04 - 1934.136 * t);
        var lambda   = sunLon - 0.00569 - 0.00478 * Math.sin(omegaRad);

        var epsilonBase = 23.0 + (26.0 + (21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813))) / 60.0) / 60.0;
        var epsilon     = epsilonBase + 0.00256 * Math.cos(omegaRad);
        var epsilonRad  = Math.toRadians(epsilon);

        var delta = Math.asin(Math.sin(epsilonRad) * Math.sin(Math.toRadians(lambda)));

        var e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);

        var L0rad       = Math.toRadians(L0);
        var tanHalfEps  = Math.tan(epsilonRad / 2.0);
        var y           = tanHalfEps * tanHalfEps;
        var eqTime = 4.0 * Math.toDegrees(
            y * Math.sin(2.0 * L0rad)
            - 2.0 * e * Math.sin(Mrad)
            + 4.0 * e * y * Math.sin(Mrad) * Math.cos(2.0 * L0rad)
            - 0.5 * y * y * Math.sin(4.0 * L0rad)
            - 1.25 * e * e * Math.sin(2.0 * Mrad)
        );

        return {:delta => delta, :eqTime => eqTime};
    }

    static function _normaliseDay(seconds as Lang.Number) as Lang.Number {
        var s = seconds;
        while (s < 0)      { s += 86400; }
        while (s >= 86400) { s -= 86400; }
        return s;
    }
}
