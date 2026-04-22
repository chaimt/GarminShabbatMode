using Toybox.Lang;
using Toybox.Math;
using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

// Determines whether the current moment falls within the Shabbat window
// (Friday sunset → Saturday nightfall) and provides countdown data.
//
// Day-of-week convention (Gregorian.Info.day_of_week):
//   1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday
class ShabbatWindowService {

    // Cached location
    private var _lat as Lang.Float;
    private var _lon as Lang.Float;
    private var _hasLocation as Lang.Boolean;

    // UTC offset in seconds (local = UTC + offset)
    private var _utcOffsetSeconds as Lang.Number;

    // Cache key: year*10000 + month*100 + day, so we recalculate once per local day
    private var _cachedDayId as Lang.Number;

    // Pre-calculated values (local seconds from midnight, 0–86399)
    private var _fridaySunsetLocal as Lang.Number;          // today's sunset when dow==6
    private var _saturdayNightfallLocal as Lang.Number;     // today's nightfall when dow==7, or tomorrow's when dow==6
    private var _nextFridayDaysAhead as Lang.Number;        // how many days until next Friday
    private var _nextFridaySunsetLocal as Lang.Number;      // next Friday's sunset in local seconds

    private var _logger as Logger?;

    function initialize() {
        _lat = 0.0;
        _lon = 0.0;
        _hasLocation = false;
        _utcOffsetSeconds = 0;
        _cachedDayId = -1;
        _fridaySunsetLocal = 64800;      // 18:00 fallback
        _saturdayNightfallLocal = 72000; // 20:00 fallback
        _nextFridayDaysAhead = 0;
        _nextFridaySunsetLocal = 64800;

        try {
            _logger = new Logger();
        } catch (ex instanceof Lang.Exception) {
            _logger = null;
        }

        _acquireLocation();
        _updateUtcOffset();
    }

    // True if the current moment is between Friday sunset and Saturday nightfall.
    function isShabbat() as Lang.Boolean {
        _ensureCalculated();

        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dow = info.day_of_week;
        var clock = System.getClockTime();
        var localNow = clock.hour * 3600 + clock.min * 60 + clock.sec;

        if (dow == 6) {           // Friday
            return localNow >= _fridaySunsetLocal;
        } else if (dow == 7) {    // Saturday
            return localNow < _saturdayNightfallLocal;
        }
        return false;
    }

    // Seconds until the next Shabbat begins (returns 0 when Shabbat is active).
    function getSecondsUntilShabbat() as Lang.Number {
        _ensureCalculated();

        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dow = info.day_of_week;
        var clock = System.getClockTime();
        var localNow = clock.hour * 3600 + clock.min * 60 + clock.sec;

        if (dow == 6 && localNow < _fridaySunsetLocal) {
            // Friday before sunset
            return _fridaySunsetLocal - localNow;
        }

        if (dow == 7 && localNow >= _saturdayNightfallLocal) {
            // Saturday after nightfall – next Shabbat is _nextFridayDaysAhead days away
            var secs = _nextFridayDaysAhead * 86400 + (_nextFridaySunsetLocal - localNow);
            return secs > 0 ? secs : secs + 86400;
        }

        if (dow != 6 && dow != 7) {
            // Sunday through Thursday
            var secs = _nextFridayDaysAhead * 86400 + (_nextFridaySunsetLocal - localNow);
            return secs > 0 ? secs : secs + 86400;
        }

        return 0; // Shabbat is currently active
    }

    // Human-readable countdown string, e.g. "5d 07:30" or "01:45".
    function getFormattedCountdown() as Lang.String {
        var seconds = getSecondsUntilShabbat();
        if (seconds <= 0) {
            return "";
        }

        var days = seconds / 86400;
        var remaining = seconds % 86400;
        var hours = remaining / 3600;
        var minutes = (remaining % 3600) / 60;

        if (days > 0) {
            return Lang.format("$1$d $2$:$3$", [
                days,
                hours.format("%02d"),
                minutes.format("%02d")
            ]);
        } else {
            return Lang.format("$1$:$2$", [
                hours.format("%02d"),
                minutes.format("%02d")
            ]);
        }
    }

    // "HH:MM" string for when Shabbat ends tonight (Saturday nightfall).
    // Only meaningful when isShabbat() is true on Saturday.
    function getNightfallTimeString() as Lang.String {
        _ensureCalculated();
        var h = _saturdayNightfallLocal / 3600;
        var m = (_saturdayNightfallLocal % 3600) / 60;
        return Lang.format("$1$:$2$", [h.format("%02d"), m.format("%02d")]);
    }

    function hasLocation() as Lang.Boolean {
        return _hasLocation;
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    // Recalculate sunset/nightfall times if the local calendar day has changed.
    private function _ensureCalculated() as Void {
        if (!_hasLocation) {
            _acquireLocation();
        }

        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var dayId = info.year * 10000 + info.month * 100 + info.day;

        if (dayId != _cachedDayId) {
            _cachedDayId = dayId;
            _updateUtcOffset();
            _calculateForDay(now.value(), info.day_of_week);
        }
    }

    // Core calculation: pre-compute all sunset/nightfall values for today's dow.
    // Uses the same tzais method as ShabbatTimeService so that the battery conservation
    // boundary always matches the time displayed on screen (T080).
    private function _calculateForDay(nowGarmin as Lang.Number, dow as Lang.Number) as Void {
        var config       = new TimeConfiguration();
        var tzaisMethod  = config.getTzaisMethod();
        var fixedMinutes = config.getShabbatEndOffset();

        if (dow == 6) {
            // Friday: today's sunset starts Shabbat; tomorrow's nightfall ends it.
            var nToday = SunCalculator.nFromGarminEpoch(nowGarmin);
            _fridaySunsetLocal = _sunsetLocalSeconds(nToday);

            var nTomorrow = SunCalculator.nFromGarminEpoch(nowGarmin + 86400);
            _saturdayNightfallLocal = _tzaisLocalSeconds(nTomorrow, tzaisMethod, fixedMinutes);

            // Pre-calc next week's Friday for after-Shabbat countdown
            _nextFridayDaysAhead = 7;
            _nextFridaySunsetLocal = _sunsetLocalSeconds(SunCalculator.nFromGarminEpoch(nowGarmin + 7 * 86400));

        } else if (dow == 7) {
            // Saturday: tonight's nightfall ends Shabbat.
            var nToday = SunCalculator.nFromGarminEpoch(nowGarmin);
            _saturdayNightfallLocal = _tzaisLocalSeconds(nToday, tzaisMethod, fixedMinutes);
            _fridaySunsetLocal = 0;

            // Next Shabbat is 6 days away (next Friday)
            _nextFridayDaysAhead = 6;
            _nextFridaySunsetLocal = _sunsetLocalSeconds(SunCalculator.nFromGarminEpoch(nowGarmin + 6 * 86400));

        } else {
            // Sunday(1) through Thursday(5): days until Friday = 6 - dow
            _nextFridayDaysAhead = 6 - dow;
            _nextFridaySunsetLocal = _sunsetLocalSeconds(
                SunCalculator.nFromGarminEpoch(nowGarmin + _nextFridayDaysAhead * 86400)
            );
            _fridaySunsetLocal = 0;
            _saturdayNightfallLocal = 0;
        }
    }

    // Calculate sunset for the given n as local seconds from midnight.
    // Falls back to 18:00 (64800 seconds) when location is unavailable or polar.
    private function _sunsetLocalSeconds(n as Lang.Float) as Lang.Number {
        if (!_hasLocation) {
            return 64800; // 18:00 default
        }
        var utcSeconds = SunCalculator.calculateSunsetAtZenithUTC(_lat, _lon, n, GEOMETRIC_ZENITH + 0.8333f);
        if (utcSeconds == null) {
            return 64800; // Polar fallback
        }
        return _normalizeDay(utcSeconds + _utcOffsetSeconds);
    }

    // Calculate tzais (nightfall) using the same method as ShabbatTimeService.
    // Falls back to sunset + 42 min when location unavailable or polar.
    private function _tzaisLocalSeconds(n as Lang.Float, method as Lang.String, fixedMinutes as Lang.Number) as Lang.Number {
        if (!_hasLocation) {
            return _normalizeDay(64800 + fixedMinutes * 60); // 18:00 + offset fallback
        }
        var tzais = SunCalculator.calculateTzaisLocalSeconds(
            _lat, _lon, n, _utcOffsetSeconds, method, fixedMinutes
        );
        if (tzais == -1) {
            return _normalizeDay(64800 + fixedMinutes * 60); // Polar fallback
        }
        return tzais;
    }

    // Normalise a seconds value into [0, 86400).
    private function _normalizeDay(seconds as Lang.Number) as Lang.Number {
        var s = seconds;
        while (s < 0) { s += 86400; }
        while (s >= 86400) { s -= 86400; }
        return s;
    }

    // Try GPS, then fall back to user-configured manual coordinates.
    private function _acquireLocation() as Void {
        try {
            var posInfo = Position.getInfo();
            if (posInfo != null && posInfo.position != null) {
                var coords = posInfo.position.toDegrees();
                if (coords != null && coords.size() >= 2) {
                    var lat = coords[0].toFloat();
                    var lon = coords[1].toFloat();
                    if (lat != 0.0 || lon != 0.0) {
                        _lat = lat;
                        _lon = lon;
                        _hasLocation = true;
                        if (_logger != null) {
                            _logger.info("Shabbat service: GPS location " + _lat + ", " + _lon);
                        }
                        return;
                    }
                }
            }
        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.warn("Shabbat service: GPS unavailable - " + ex.getErrorMessage());
            }
        }

        // Manual coordinates from user settings
        var config = new TimeConfiguration();
        var lat = config.getManualLatitude();
        var lon = config.getManualLongitude();
        if (lat != 0.0 || lon != 0.0) {
            _lat = lat;
            _lon = lon;
            _hasLocation = true;
            if (_logger != null) {
                _logger.info("Shabbat service: manual location " + _lat + ", " + _lon);
            }
        } else {
            _hasLocation = false;
            if (_logger != null) {
                _logger.warn("Shabbat service: no location – using 18:00 fallback");
            }
        }
    }

    // Derive the UTC offset by comparing Garmin epoch modulo against local clock.
    // This handles DST automatically because System.getClockTime() is always local.
    private function _updateUtcOffset() as Void {
        var nowGarmin = Time.now().value();
        // Garmin epoch starts at UTC midnight, so mod 86400 = seconds since last UTC midnight
        var utcSecondsInDay = nowGarmin % 86400;
        var clock = System.getClockTime();
        var localSecondsInDay = clock.hour * 3600 + clock.min * 60 + clock.sec;
        _utcOffsetSeconds = localSecondsInDay - utcSecondsInDay;
        // Clamp to realistic range [-43200, +43200] (UTC-12 to UTC+12)
        while (_utcOffsetSeconds > 43200) { _utcOffsetSeconds -= 86400; }
        while (_utcOffsetSeconds < -43200) { _utcOffsetSeconds += 86400; }
    }
}
