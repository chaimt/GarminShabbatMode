using Toybox.Lang;
using Toybox.Application;

// Caches one day's AstronomicalData in device persistent storage so that
// repeated calls within the same calendar day are O(1) reads from storage
// rather than recomputing trigonometric solar position formulas.
class CalculationCache {

    private const KEY_DAY_ID        = "calc_day_id";
    private const KEY_SUNRISE       = "calc_sunrise";
    private const KEY_SUNSET        = "calc_sunset";
    private const KEY_LAT           = "calc_lat";
    private const KEY_LON           = "calc_lon";
    private const KEY_IS_POLAR      = "calc_polar";

    private var _memoryCache as AstronomicalData?;
    private var _memoryCacheDayId as Lang.Number;

    function initialize() {
        _memoryCache = null;
        _memoryCacheDayId = -1;
    }

    // Return cached data if it matches today's dayId; null otherwise.
    function get(dayId as Lang.Number) as AstronomicalData? {
        // Fast path: in-memory cache hit
        if (_memoryCache != null && _memoryCacheDayId == dayId) {
            return _memoryCache;
        }

        // Slow path: check persistent storage
        try {
            var storedDayId = Application.Storage.getValue(KEY_DAY_ID);
            if (storedDayId != null && (storedDayId as Lang.Number) == dayId) {
                var sunrise  = _readNumber(KEY_SUNRISE, -1);
                var sunset   = _readNumber(KEY_SUNSET,  -1);
                var lat      = _readFloat(KEY_LAT,   0.0);
                var lon      = _readFloat(KEY_LON,   0.0);
                var isPolar  = _readBoolean(KEY_IS_POLAR, false);

                var data = new AstronomicalData();
                data.configure(lat, lon, dayId, sunrise, sunset, isPolar);

                _memoryCache = data;
                _memoryCacheDayId = dayId;
                return data;
            }
        } catch (ex instanceof Lang.Exception) {
            // Treat any storage error as a cache miss
        }
        return null;
    }

    // Persist an AstronomicalData record.
    function store(dayId as Lang.Number, data as AstronomicalData) as Void {
        _memoryCache = data;
        _memoryCacheDayId = dayId;

        try {
            Application.Storage.setValue(KEY_DAY_ID,   dayId);
            Application.Storage.setValue(KEY_SUNRISE,  data.getSunriseLocalSeconds());
            Application.Storage.setValue(KEY_SUNSET,   data.getSunsetLocalSeconds());
            Application.Storage.setValue(KEY_LAT,      data.getLatitude());
            Application.Storage.setValue(KEY_LON,      data.getLongitude());
            Application.Storage.setValue(KEY_IS_POLAR, data.isPolarRegion());
        } catch (ex instanceof Lang.Exception) {
            // Non-fatal: in-memory cache still valid
        }
    }

    // Evict both in-memory and persistent caches.
    function clear() as Void {
        _memoryCache = null;
        _memoryCacheDayId = -1;
        try {
            Application.Storage.deleteValue(KEY_DAY_ID);
            Application.Storage.deleteValue(KEY_SUNRISE);
            Application.Storage.deleteValue(KEY_SUNSET);
            Application.Storage.deleteValue(KEY_LAT);
            Application.Storage.deleteValue(KEY_LON);
            Application.Storage.deleteValue(KEY_IS_POLAR);
        } catch (ex instanceof Lang.Exception) {
            // ignore
        }
    }

    // -------------------------------------------------------------------------
    // Storage helpers
    // -------------------------------------------------------------------------

    private function _readNumber(key as Lang.String, defaultVal as Lang.Number) as Lang.Number {
        var v = Application.Storage.getValue(key);
        if (v instanceof Lang.Number) { return v as Lang.Number; }
        return defaultVal;
    }

    private function _readFloat(key as Lang.String, defaultVal as Lang.Float) as Lang.Float {
        var v = Application.Storage.getValue(key);
        if (v instanceof Lang.Float)  { return v as Lang.Float; }
        if (v instanceof Lang.Number) { return (v as Lang.Number).toFloat(); }
        return defaultVal;
    }

    private function _readBoolean(key as Lang.String, defaultVal as Lang.Boolean) as Lang.Boolean {
        var v = Application.Storage.getValue(key);
        if (v instanceof Lang.Boolean) { return v as Lang.Boolean; }
        return defaultVal;
    }
}
