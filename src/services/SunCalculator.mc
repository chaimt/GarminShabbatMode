using Toybox.Lang;
using Toybox.Math;

// Garmin epoch = Jan 1, 1990, 00:00:00 UTC
// J2000.0    = Jan 1, 2000, 12:00:00 UTC
// Difference = 3652.5 days * 86400 s/day = 315,576,000 seconds
const SOLAR_J2000_GARMIN_OFFSET = 315576000;

// Implements the NOAA simplified solar position algorithm.
// Accuracy: approximately ±1-2 minutes for sunset time at typical latitudes.
class SunCalculator {

    // Compute n (days since J2000.0) from a Garmin epoch value (seconds since Jan 1, 1990 UTC).
    static function nFromGarminEpoch(garminEpochSeconds as Lang.Number) as Lang.Float {
        return (garminEpochSeconds - SOLAR_J2000_GARMIN_OFFSET).toFloat() / 86400.0;
    }

    // Calculate sunset time in seconds since midnight UTC.
    //
    // lat : latitude in degrees, positive = North
    // lon : longitude in degrees, positive = East
    // n   : days since J2000.0 (use nFromGarminEpoch())
    //
    // Returns seconds from midnight UTC (0–86399), or null for polar regions
    // (midnight sun / polar night).
    static function calculateSunsetUTC(lat as Lang.Float, lon as Lang.Float, n as Lang.Float) as Lang.Number? {
        // Julian century from J2000.0
        var t = n / 36525.0;

        // Geometric mean longitude of the sun (degrees), mod 360
        var L0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
        L0 = L0 - Math.floor(L0 / 360.0) * 360.0;

        // Geometric mean anomaly (degrees), mod 360
        var M = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
        M = M - Math.floor(M / 360.0) * 360.0;
        var Mrad = Math.toRadians(M);

        // Equation of center
        var C = (1.914602 - 0.004817 * t - 0.000014 * t * t) * Math.sin(Mrad)
              + (0.019993 - 0.000101 * t) * Math.sin(2.0 * Mrad)
              + 0.000289 * Math.sin(3.0 * Mrad);

        // Sun's true longitude, then apparent longitude
        var sunLon = L0 + C;
        var omegaRad = Math.toRadians(125.04 - 1934.136 * t);
        var lambda = sunLon - 0.00569 - 0.00478 * Math.sin(omegaRad);

        // Obliquity of the ecliptic (degrees)
        var epsilonBase = 23.0 + (26.0 + (21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813))) / 60.0) / 60.0;
        var epsilon = epsilonBase + 0.00256 * Math.cos(omegaRad);
        var epsilonRad = Math.toRadians(epsilon);

        // Solar declination (radians)
        var delta = Math.asin(Math.sin(epsilonRad) * Math.sin(Math.toRadians(lambda)));

        // Earth's orbital eccentricity
        var e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);

        // Equation of time (minutes)
        var L0rad = Math.toRadians(L0);
        var tanHalfEps = Math.tan(epsilonRad / 2.0);
        var y = tanHalfEps * tanHalfEps;
        var EqTime = 4.0 * Math.toDegrees(
            y * Math.sin(2.0 * L0rad)
            - 2.0 * e * Math.sin(Mrad)
            + 4.0 * e * y * Math.sin(Mrad) * Math.cos(2.0 * L0rad)
            - 0.5 * y * y * Math.sin(4.0 * L0rad)
            - 1.25 * e * e * Math.sin(2.0 * Mrad)
        );

        // Hour angle at sunset: sun center is -0.8333° (accounts for refraction + solar disc)
        var latRad = Math.toRadians(lat);
        var cosH = (Math.sin(Math.toRadians(-0.8333)) - Math.sin(latRad) * Math.sin(delta))
                 / (Math.cos(latRad) * Math.cos(delta));

        // Polar check: |cosH| > 1 means no sunset (or no sunrise) today
        if (cosH > 1.0 || cosH < -1.0) {
            return null;
        }

        var H = Math.toDegrees(Math.acos(cosH)); // degrees (0-180)

        // Solar noon in minutes from midnight UTC
        var solarNoon = 720.0 - 4.0 * lon - EqTime;

        // Sunset in minutes from midnight UTC
        var sunsetMinutes = solarNoon + 4.0 * H;

        // Normalize to [0, 1440)
        sunsetMinutes = sunsetMinutes - Math.floor(sunsetMinutes / 1440.0) * 1440.0;

        return (sunsetMinutes * 60.0).toNumber();
    }
}
