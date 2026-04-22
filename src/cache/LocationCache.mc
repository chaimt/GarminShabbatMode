using Toybox.Lang;
using Toybox.Application;
using Toybox.System;

// Persists the last-known GPS location to device storage.
// Allows the app to function with the cached location for up to 24 hours
// when GPS is temporarily unavailable (FR-007).
class LocationCache {

    private const KEY_LAT = "cache_lat";
    private const KEY_LON = "cache_lon";
    private const KEY_TIMESTAMP = "cache_loc_ts";
    private const MAX_AGE_SECONDS = 86400; // 24 hours

    private var _logger as Logger?;

    function initialize() {
        try {
            _logger = new Logger();
        } catch (ex instanceof Lang.Exception) {
            _logger = null;
        }
    }

    // Save a location fix to persistent storage.
    function save(lat as Lang.Float, lon as Lang.Float) as Void {
        try {
            Application.Storage.setValue(KEY_LAT, lat);
            Application.Storage.setValue(KEY_LON, lon);
            Application.Storage.setValue(KEY_TIMESTAMP, System.getTimer() / 1000);
            if (_logger != null) {
                _logger.debug("LocationCache: saved " + lat + ", " + lon);
            }
        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.warn("LocationCache save failed: " + ex.getErrorMessage());
            }
        }
    }

    // Return true if a usable, non-expired cached location exists.
    function hasValidCache() as Lang.Boolean {
        try {
            var ts = Application.Storage.getValue(KEY_TIMESTAMP);
            if (ts == null) { return false; }
            var age = (System.getTimer() / 1000) - (ts as Lang.Number);
            return age >= 0 && age < MAX_AGE_SECONDS;
        } catch (ex instanceof Lang.Exception) {
            return false;
        }
    }

    // Retrieve cached latitude; returns 0.0 if unavailable.
    function getCachedLatitude() as Lang.Float {
        try {
            var val = Application.Storage.getValue(KEY_LAT);
            if (val instanceof Lang.Float) { return val as Lang.Float; }
            if (val instanceof Lang.Number) { return (val as Lang.Number).toFloat(); }
        } catch (ex instanceof Lang.Exception) {
            // ignore
        }
        return 0.0;
    }

    // Retrieve cached longitude; returns 0.0 if unavailable.
    function getCachedLongitude() as Lang.Float {
        try {
            var val = Application.Storage.getValue(KEY_LON);
            if (val instanceof Lang.Float) { return val as Lang.Float; }
            if (val instanceof Lang.Number) { return (val as Lang.Number).toFloat(); }
        } catch (ex instanceof Lang.Exception) {
            // ignore
        }
        return 0.0;
    }

    // Age of cached location in seconds; -1 if no cache.
    function getCacheAgeSeconds() as Lang.Number {
        try {
            var ts = Application.Storage.getValue(KEY_TIMESTAMP);
            if (ts == null) { return -1; }
            return (System.getTimer() / 1000) - (ts as Lang.Number);
        } catch (ex instanceof Lang.Exception) {
            return -1;
        }
    }

    // Clear the stored location.
    function clear() as Void {
        try {
            Application.Storage.deleteValue(KEY_LAT);
            Application.Storage.deleteValue(KEY_LON);
            Application.Storage.deleteValue(KEY_TIMESTAMP);
        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.warn("LocationCache clear failed: " + ex.getErrorMessage());
            }
        }
    }
}
