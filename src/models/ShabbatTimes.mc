using Toybox.Lang;

// Holds the candle-lighting and end-of-Shabbat (havdalah/nightfall) times
// for a specific Friday/Saturday.
// Times are stored as local seconds from midnight (0–86399).
// A value of -1 indicates the time cannot be calculated (e.g. polar region).
class ShabbatTimes {

    private var _candleLightingLocalSeconds as Lang.Number;
    private var _shabbatEndLocalSeconds as Lang.Number;
    private var _sunsetLocalSeconds as Lang.Number;
    private var _candleOffset as Lang.Number;  // minutes before sunset
    private var _endOffset as Lang.Number;     // minutes after sunset
    private var _dayId as Lang.Number;
    private var _isValid as Lang.Boolean;

    private const INVALID = -1;

    function initialize() {
        _candleLightingLocalSeconds = INVALID;
        _shabbatEndLocalSeconds     = INVALID;
        _sunsetLocalSeconds         = INVALID;
        _candleOffset = 18;
        _endOffset    = 25;
        _dayId   = 0;
        _isValid = false;
    }

    // Compute from a known sunset time (local seconds from midnight).
    function configureFromSunset(
        sunsetLocalSecs as Lang.Number,
        candleOffsetMinutes as Lang.Number,
        endOffsetMinutes as Lang.Number,
        dayId as Lang.Number
    ) as Void {
        _sunsetLocalSeconds = sunsetLocalSecs;
        _candleOffset = candleOffsetMinutes;
        _endOffset    = endOffsetMinutes;
        _dayId = dayId;

        if (sunsetLocalSecs != INVALID) {
            _candleLightingLocalSeconds = _normalise(sunsetLocalSecs - candleOffsetMinutes * 60);
            _shabbatEndLocalSeconds     = _normalise(sunsetLocalSecs + endOffsetMinutes    * 60);
            _isValid = true;
        } else {
            _candleLightingLocalSeconds = INVALID;
            _shabbatEndLocalSeconds     = INVALID;
            _isValid = false;
        }
    }

    function hasCandleLighting() as Lang.Boolean {
        return _candleLightingLocalSeconds != INVALID;
    }

    function hasShabbatEnd() as Lang.Boolean {
        return _shabbatEndLocalSeconds != INVALID;
    }

    function getCandleLightingLocalSeconds() as Lang.Number {
        return _candleLightingLocalSeconds;
    }

    function getShabbatEndLocalSeconds() as Lang.Number {
        return _shabbatEndLocalSeconds;
    }

    function getSunsetLocalSeconds() as Lang.Number {
        return _sunsetLocalSeconds;
    }

    function getCandleOffsetMinutes() as Lang.Number {
        return _candleOffset;
    }

    function getEndOffsetMinutes() as Lang.Number {
        return _endOffset;
    }

    function getDayId() as Lang.Number {
        return _dayId;
    }

    function isValid() as Lang.Boolean {
        return _isValid;
    }

    // -------------------------------------------------------------------------
    private function _normalise(seconds as Lang.Number) as Lang.Number {
        var s = seconds;
        while (s < 0)           { s += 86400; }
        while (s >= 86400) { s -= 86400; }
        return s;
    }
}
