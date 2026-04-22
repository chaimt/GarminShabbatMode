using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

// High-level Shabbat time service.
// Delegates core sunset/nightfall computation to ShabbatWindowService and
// wraps the result in a ShabbatTimes data model with configurable offsets.
// Also exposes the candle-lighting time (configurable minutes before sunset).
class ShabbatTimeService {

    private var _windowService as ShabbatWindowService;
    private var _astronomicalService as AstronomicalService;
    private var _config as TimeConfiguration;
    private var _cachedTimes as ShabbatTimes?;
    private var _cachedDayId as Lang.Number;
    private var _logger as Logger?;

    function initialize() {
        _windowService       = new ShabbatWindowService();
        _astronomicalService = new AstronomicalService();
        _config              = new TimeConfiguration();
        _cachedTimes         = null;
        _cachedDayId         = -1;

        try {
            _logger = new Logger();
        } catch (ex instanceof Lang.Exception) {
            _logger = null;
        }
    }

    // Refresh location data; call when location may have changed.
    function refresh() as Void {
        _astronomicalService.refresh();
        _cachedTimes  = null;   // invalidate cache so times recompute
        _cachedDayId  = -1;
    }

    // Return Shabbat times for today (candle lighting + end of Shabbat).
    // Results are cached for the current calendar day.
    // Supports both fixed-minute and degree-based tzais methods (FR-014).
    function getShabbatTimes() as ShabbatTimes? {
        var dayId = DateMath.todayDayId();
        if (_cachedTimes != null && _cachedDayId == dayId) {
            return _cachedTimes;
        }

        var times        = new ShabbatTimes();
        var candleOffset = _config.getCandleLightingOffset();
        var tzaisMethod  = _config.getTzaisMethod();
        var sunsetSecs   = _getSunsetLocalSeconds();

        if (!tzaisMethod.equals("fixed_minutes") && _hasLocationData()) {
            // Degree-based path: calculate tzais via solar zenith angle
            var lat    = _astronomicalService.hasData()
                ? (_astronomicalService.getAstronomicalData() != null
                    ? (_astronomicalService.getAstronomicalData() as AstronomicalData).getLatitude()
                    : 0.0f)
                : 0.0f;
            var lon    = _astronomicalService.hasData()
                ? (_astronomicalService.getAstronomicalData() != null
                    ? (_astronomicalService.getAstronomicalData() as AstronomicalData).getLongitude()
                    : 0.0f)
                : 0.0f;
            var nowGarmin   = Time.now().value();
            var n           = SunCalculator.nFromGarminEpoch(nowGarmin);
            var utcOffset   = _getUtcOffsetSeconds();
            var tzaisSecs   = SunCalculator.calculateTzaisLocalSeconds(
                lat, lon, n, utcOffset, tzaisMethod, _config.getShabbatEndOffset()
            );
            times.configureDegreeBasedTzais(sunsetSecs, tzaisSecs, candleOffset, dayId);
        } else {
            // Fixed-minute path (default, Rabbeinu Tam 42 min)
            times.configureFromSunset(sunsetSecs, candleOffset, _config.getShabbatEndOffset(), dayId);
        }

        _cachedTimes = times;
        _cachedDayId = dayId;

        if (_logger != null) {
            _logger.info("ShabbatTimeService[" + tzaisMethod + "]: candle=" +
                         times.getCandleLightingLocalSeconds() +
                         "s, end=" + times.getShabbatEndLocalSeconds() + "s");
        }

        return times;
    }

    // True if the current moment falls inside the Shabbat window.
    function isShabbat() as Lang.Boolean {
        return _windowService.isShabbat();
    }

    // Seconds until the next Shabbat begins (0 if Shabbat is now active).
    function getSecondsUntilShabbat() as Lang.Number {
        return _windowService.getSecondsUntilShabbat();
    }

    // Human-readable countdown string.
    function getFormattedCountdown() as Lang.String {
        return _windowService.getFormattedCountdown();
    }

    // "HH:MM" for when Shabbat ends this Saturday night.
    function getNightfallTimeString() as Lang.String {
        return _windowService.getNightfallTimeString();
    }

    function hasLocation() as Lang.Boolean {
        return _windowService.hasLocation();
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    // Return today's sunset as local seconds, sourced from AstronomicalService.
    // Falls back to -1 (unknown) if location/calculation is unavailable.
    private function _getSunsetLocalSeconds() as Lang.Number {
        if (_astronomicalService.hasData()) {
            var data = _astronomicalService.getAstronomicalData();
            if (data != null && data.hasSunset()) {
                return data.getSunsetLocalSeconds();
            }
        }
        return -1;
    }

    private function _hasLocationData() as Lang.Boolean {
        return _astronomicalService.hasData() && _astronomicalService.getAstronomicalData() != null;
    }

    private function _getUtcOffsetSeconds() as Lang.Number {
        var nowGarmin = Time.now().value();
        var utcSecondsInDay = nowGarmin % 86400;
        var clock = System.getClockTime();
        var localSecondsInDay = clock.hour * 3600 + clock.min * 60 + clock.sec;
        var offset = localSecondsInDay - utcSecondsInDay;
        while (offset > 43200)  { offset -= 86400; }
        while (offset < -43200) { offset += 86400; }
        return offset;
    }
}
