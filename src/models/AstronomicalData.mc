using Toybox.Lang;

// Holds today's computed sunrise and sunset times for a specific location.
// Times are stored as local seconds from midnight (0–86399).
// A value of -1 indicates the event does not occur (polar midnight/midnight sun).
class AstronomicalData {

    private var _sunriseLocalSeconds as Lang.Number;
    private var _sunsetLocalSeconds as Lang.Number;
    private var _latitude as Lang.Float;
    private var _longitude as Lang.Float;
    private var _dayId as Lang.Number; // year*10000 + month*100 + day
    private var _isPolarRegion as Lang.Boolean;

    private const INVALID = -1;

    function initialize() {
        _sunriseLocalSeconds = INVALID;
        _sunsetLocalSeconds  = INVALID;
        _latitude  = 0.0;
        _longitude = 0.0;
        _dayId = 0;
        _isPolarRegion = false;
    }

    // Populate data for a given location and day.
    function configure(
        lat as Lang.Float,
        lon as Lang.Float,
        dayId as Lang.Number,
        sunriseLocalSecs as Lang.Number,
        sunsetLocalSecs as Lang.Number,
        isPolar as Lang.Boolean
    ) as Void {
        _latitude  = lat;
        _longitude = lon;
        _dayId     = dayId;
        _sunriseLocalSeconds = sunriseLocalSecs;
        _sunsetLocalSeconds  = sunsetLocalSecs;
        _isPolarRegion = isPolar;
    }

    // Returns true when sunrise data is available.
    function hasSunrise() as Lang.Boolean {
        return _sunriseLocalSeconds != INVALID;
    }

    // Returns true when sunset data is available.
    function hasSunset() as Lang.Boolean {
        return _sunsetLocalSeconds != INVALID;
    }

    function getSunriseLocalSeconds() as Lang.Number {
        return _sunriseLocalSeconds;
    }

    function getSunsetLocalSeconds() as Lang.Number {
        return _sunsetLocalSeconds;
    }

    function getLatitude() as Lang.Float {
        return _latitude;
    }

    function getLongitude() as Lang.Float {
        return _longitude;
    }

    // Day identifier: year*10000 + month*100 + day (matches Gregorian.Info pattern).
    function getDayId() as Lang.Number {
        return _dayId;
    }

    function isPolarRegion() as Lang.Boolean {
        return _isPolarRegion;
    }

    // True when neither sunrise nor sunset is available.
    function isUnusable() as Lang.Boolean {
        return _sunriseLocalSeconds == INVALID && _sunsetLocalSeconds == INVALID;
    }
}
