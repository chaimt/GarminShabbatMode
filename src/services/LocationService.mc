using Toybox.Lang;
using Toybox.Position;
using Toybox.System;

// Acquires and caches the device's current GPS coordinates.
// Supports two location-source modes controlled by Configuration.location_auto:
//   "gps"    (default) — acquires via GPS hardware, caches up to 24 h.
//   "manual" — reads persisted lat/lon from Application.Storage, no GPS radio use.
//
// Source mode is read fresh from storage on every refresh() call so that a
// settings change takes effect immediately without restarting the service
// (satisfies T012 / FR-007).
//
// Active GPS acquisition: call startGpsTracking(callback) to turn on the GPS
// radio via Position.enableLocationEvents(LOCATION_ONE_SHOT, ...).  The radio
// turns off automatically after the first fix is delivered to the callback.
// startGpsTracking() is a no-op when source is "manual".
//
// Battery optimisation: GPS is only actively queried once per
// UPDATE_INTERVAL_SECONDS (default 5 minutes).  Between polls the last known
// coordinates are served from the in-memory cache.
class LocationService {

    private var _updateIntervalSeconds as Lang.Number; // default 5 minutes

    private var _lat as Lang.Float;
    private var _lon as Lang.Float;
    private var _hasLocation as Lang.Boolean;
    private var _source as Lang.String;
    private var _lastRefreshTimer as Lang.Number; // System.getTimer() value
    private var _isGpsTracking as Lang.Boolean;
    private var _logger as Logger?;

    function initialize() {
        _updateIntervalSeconds = 300; // 5 minutes default
        _lat = 0.0;
        _lon = 0.0;
        _hasLocation = false;
        _source = "none";
        _lastRefreshTimer = 0;
        _isGpsTracking = false;

        try {
            _logger = new Logger();
        } catch (ex instanceof Lang.Exception) {
            _logger = null;
        }

        _loadFromCache();
        // Seed with the system's last-known GPS fix if available and source is GPS.
        // Position.getInfo() returns the OS-cached position synchronously — no
        // radio activation — so this costs nothing and provides instant location
        // availability on first launch before any timer fires (US6 / T022).
        if (!_isManualMode(_loadStorageSettings())) {
            _loadSystemLastKnown();
        }
    }

    // Attempt to acquire a fresh location.
    // When source is "manual": returns stored manual coordinates immediately,
    //   no GPS radio activation (GPS suppression — FR-006).
    // When source is "gps": tries live GPS first, falls back to manual coords.
    // Rate-limited to once per UPDATE_INTERVAL_SECONDS to conserve battery.
    // Storage is read once per refresh cycle (not twice) to avoid repeated
    // StorageManager instantiation on a hot path (H1 fix).
    // Returns true if any location is available after the call.
    function refresh() as Lang.Boolean {
        var now = System.getTimer();
        // Allow immediate query on first call (_lastRefreshTimer == 0)
        if (_lastRefreshTimer != 0 && _hasLocation &&
            (now - _lastRefreshTimer) < _updateIntervalSeconds * 1000) {
            return _hasLocation; // Serve cached value within rate-limit window
        }
        _lastRefreshTimer = now;

        // Load persisted settings once for this refresh cycle.  Passing the dict
        // to helpers avoids a second StorageManager.initialize() call (FR-007 / H1).
        var settings = _loadStorageSettings();

        if (_isManualMode(settings)) {
            return _tryManual(settings);
        }

        if (_tryGps()) {
            return true;
        }
        return _tryManual(settings);
    }

    // Force a GPS/manual query regardless of rate limit (e.g. on app foreground).
    function forceRefresh() as Lang.Boolean {
        _lastRefreshTimer = 0;
        return refresh();
    }

    // Call after the user changes the location source in settings.
    // Clears the cached location so the next refresh() re-resolves from the
    // correct source.  If switching back to GPS, a fresh acquisition begins.
    function onSourceChanged() as Void {
        _hasLocation = false;
        _lastRefreshTimer = 0;
        if (_isGpsTracking && _isManualMode(_loadStorageSettings())) {
            // Stop any in-flight GPS request when switching to manual.
            stopGpsTracking();
        }
        if (_logger != null) {
            _logger.info("LocationService: source changed, cache cleared");
        }
    }

    function hasLocation() as Lang.Boolean {
        return _hasLocation;
    }

    function getLatitude() as Lang.Float {
        return _lat;
    }

    function getLongitude() as Lang.Float {
        return _lon;
    }

    // Human-readable source description for diagnostics.
    function getSource() as Lang.String {
        return _source;
    }

    // Actively enable GPS hardware using LOCATION_ONE_SHOT.
    // The radio fires `callback` once when a fix arrives, then turns off.
    // callback signature must match Toybox.Position.Info as the sole argument.
    // No-op when location source is "manual" (GPS suppression — FR-006).
    function startGpsTracking(callback as Lang.Method) as Void {
        if (_isManualMode(_loadStorageSettings())) {
            if (_logger != null) {
                _logger.info("LocationService: startGpsTracking skipped (manual source)");
            }
            return;
        }
        try {
            Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, callback);
            _isGpsTracking = true;
            if (_logger != null) {
                _logger.info("LocationService: GPS tracking started (ONE_SHOT)");
            }
        } catch (ex instanceof Lang.Exception) {
            _isGpsTracking = false;
            if (_logger != null) {
                _logger.warn("LocationService: startGpsTracking failed - " + ex.getErrorMessage());
            }
        }
    }

    // Stop active GPS tracking.
    // With LOCATION_ONE_SHOT the radio turns off automatically after the first fix,
    // so no explicit disable API call is needed.  We just clear the tracking flag
    // so the UI indicator updates correctly.
    function stopGpsTracking() as Void {
        _isGpsTracking = false;
        if (_logger != null) {
            _logger.info("LocationService: GPS tracking stopped");
        }
    }

    // True while a LOCATION_ONE_SHOT request is outstanding.
    function isGpsTracking() as Lang.Boolean {
        return _isGpsTracking;
    }

    // Override the GPS poll rate-limit window.
    // BatteryConservationService calls this to extend the interval to 1800 s
    // during Shabbat and restore it to 300 s afterwards.
    function setUpdateIntervalSeconds(seconds as Lang.Number) as Void {
        _updateIntervalSeconds = seconds;
        if (_logger != null) {
            _logger.info("LocationService: GPS interval set to " + seconds + "s");
        }
    }

    // Update from an explicit coordinate pair (e.g. restored from cache).
    function setLocation(lat as Lang.Float, lon as Lang.Float) as Void {
        if (LocationValidator.isValidLatitude(lat) && LocationValidator.isValidLongitude(lon)) {
            _lat = lat;
            _lon = lon;
            _hasLocation = (lat != 0.0 || lon != 0.0);
            _source = "explicit";
        }
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    // Seed location from the OS/system last-known GPS fix at startup (US6 / T022).
    // Position.getInfo() is a synchronous, zero-radio-cost read of the most recent
    // position the device has cached from any source (prior session, system, etc.).
    // If valid, overwrites the LocationCache-restored value with a potentially
    // fresher fix and persists it so subsequent restarts also benefit.
    // Called only when source = "gps" (no-op in manual mode).
    private function _loadSystemLastKnown() as Void {
        try {
            var posInfo = Position.getInfo();
            if (posInfo != null && posInfo.position != null) {
                var coords = posInfo.position.toDegrees();
                if (coords != null && coords.size() >= 2) {
                    var sysLat = coords[0].toFloat();
                    var sysLon = coords[1].toFloat();
                    if (LocationValidator.isUsable(sysLat, sysLon)) {
                        _lat = sysLat;
                        _lon = sysLon;
                        _hasLocation = true;
                        _source = "gps_system";
                        new LocationCache().save(sysLat, sysLon);
                        if (_logger != null) {
                            _logger.info("LocationService: system last-known " + sysLat + ", " + sysLon);
                        }
                    }
                }
            }
        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.warn("LocationService: _loadSystemLastKnown failed - " + ex.getErrorMessage());
            }
        }
    }

    // Restore last-known location from persistent cache at startup (SC-003).
    // Allows astronomical calculations to run immediately without waiting for GPS.
    private function _loadFromCache() as Void {
        try {
            var cache = new LocationCache();
            if (cache.hasValidCache()) {
                var lat = cache.getCachedLatitude();
                var lon = cache.getCachedLongitude();
                if (LocationValidator.isValidLatitude(lat) &&
                    LocationValidator.isValidLongitude(lon) &&
                    (lat != 0.0 || lon != 0.0)) {
                    _lat = lat;
                    _lon = lon;
                    _hasLocation = true;
                    _source = "cache";
                    if (_logger != null) {
                        _logger.info("LocationService: restored from cache " + lat + ", " + lon);
                    }
                }
            }
        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.warn("LocationService: cache restore failed - " + ex.getErrorMessage());
            }
        }
    }

    private function _tryGps() as Lang.Boolean {
        try {
            var posInfo = Position.getInfo();
            if (posInfo != null && posInfo.position != null) {
                var coords = posInfo.position.toDegrees();
                if (coords != null && coords.size() >= 2) {
                    var lat = coords[0].toFloat();
                    var lon = coords[1].toFloat();
                    if (LocationValidator.isValidLatitude(lat) &&
                        LocationValidator.isValidLongitude(lon) &&
                        (lat != 0.0 || lon != 0.0)) {
                        _lat = lat;
                        _lon = lon;
                        _hasLocation = true;
                        _source = "gps";
                        if (_logger != null) {
                            _logger.info("LocationService: GPS fix " + _lat + ", " + _lon);
                        }
                        return true;
                    }
                }
            }
        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.warn("LocationService: GPS error - " + ex.getErrorMessage());
            }
        }
        return false;
    }

    // Load the persisted USER_SETTINGS dictionary once.  Returns null on failure.
    // Callers (refresh, startGpsTracking, onSourceChanged, initialize) call this
    // once per operation and pass the result to _isManualMode() / _tryManual()
    // so we never instantiate StorageManager more than once per operation (H1 fix).
    private function _loadStorageSettings() as Lang.Dictionary<Lang.String, Lang.Object>? {
        try {
            var storage = new StorageManager();
            storage.initialize();
            return storage.getUserSettings();
        } catch (ex instanceof Lang.Exception) {
            return null;
        }
    }

    // Returns true when the user has configured manual location source.
    // Accepts a pre-loaded settings dict to avoid redundant storage reads.
    private function _isManualMode(settings as Lang.Dictionary<Lang.String, Lang.Object>?) as Lang.Boolean {
        if (settings != null && settings.hasKey("location_auto")) {
            var v = settings.get("location_auto");
            if (v instanceof Lang.Boolean) {
                return !(v as Lang.Boolean); // manual when location_auto == false
            }
        }
        return false; // Default: GPS mode
    }

    // Read manually configured coordinates from a pre-loaded settings dictionary.
    // Accepts settings to avoid a second StorageManager instantiation per refresh (H1).
    // Uses canonical "latitude"/"longitude" keys (written by _persistLocation() and
    // onGpsFix()), with "manual_latitude"/"manual_longitude" as fallback for older data.
    private function _tryManual(settings as Lang.Dictionary<Lang.String, Lang.Object>?) as Lang.Boolean {
        try {
            if (settings == null) {
                _hasLocation = false;
                return false;
            }

            var lat = 0.0;
            var lon = 0.0;
            if (settings.hasKey("latitude")) {
                var v = settings.get("latitude");
                if (v instanceof Lang.Float) { lat = v as Lang.Float; }
                else if (v instanceof Number) { lat = (v as Lang.Number).toFloat(); }
            }
            if (settings.hasKey("manual_latitude") && lat == 0.0) {
                var v = settings.get("manual_latitude");
                if (v instanceof Lang.Float) { lat = v as Lang.Float; }
                else if (v instanceof Number) { lat = (v as Lang.Number).toFloat(); }
            }
            if (settings.hasKey("longitude")) {
                var v = settings.get("longitude");
                if (v instanceof Lang.Float) { lon = v as Lang.Float; }
                else if (v instanceof Number) { lon = (v as Lang.Number).toFloat(); }
            }
            if (settings.hasKey("manual_longitude") && lon == 0.0) {
                var v = settings.get("manual_longitude");
                if (v instanceof Lang.Float) { lon = v as Lang.Float; }
                else if (v instanceof Number) { lon = (v as Lang.Number).toFloat(); }
            }

            if (LocationValidator.hasValidManualCoords(lat, lon)) {
                _lat = lat;
                _lon = lon;
                _hasLocation = true;
                _source = "manual";
                if (_logger != null) {
                    _logger.info("LocationService: manual " + _lat + ", " + _lon);
                }
                return true;
            }
        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.warn("LocationService: manual location error - " + ex.getErrorMessage());
            }
        }
        _hasLocation = false;
        return false;
    }
}
