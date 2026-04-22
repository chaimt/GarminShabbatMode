using Toybox.Lang;
using Toybox.Position;
using Toybox.System;

// Acquires and caches the device's current GPS coordinates.
// Falls back to manually configured coordinates when GPS is unavailable.
//
// Battery optimisation: GPS is only actively queried once per
// UPDATE_INTERVAL_SECONDS (default 5 minutes) to avoid continuous
// radio-on drain.  Between polls the last known coordinates are served
// from the in-memory cache.
class LocationService {

    private const UPDATE_INTERVAL_SECONDS = 300; // 5 minutes

    private var _lat as Lang.Float;
    private var _lon as Lang.Float;
    private var _hasLocation as Lang.Boolean;
    private var _source as Lang.String;
    private var _lastRefreshTimer as Lang.Number; // System.getTimer() value
    private var _logger as Logger?;

    function initialize() {
        _lat = 0.0;
        _lon = 0.0;
        _hasLocation = false;
        _source = "none";
        _lastRefreshTimer = 0;

        try {
            _logger = new Logger();
        } catch (ex instanceof Lang.Exception) {
            _logger = null;
        }
    }

    // Attempt to acquire a fresh GPS fix; fall back to manual coordinates.
    // Rate-limited to once per UPDATE_INTERVAL_SECONDS to conserve battery.
    // Returns true if any location is available after the call.
    function refresh() as Lang.Boolean {
        var now = System.getTimer();
        // Allow immediate query on first call (_lastRefreshTimer == 0)
        if (_lastRefreshTimer != 0 && _hasLocation &&
            (now - _lastRefreshTimer) < UPDATE_INTERVAL_SECONDS * 1000) {
            return _hasLocation; // Serve cached value within rate-limit window
        }
        _lastRefreshTimer = now;
        if (_tryGps()) {
            return true;
        }
        return _tryManual();
    }

    // Force a GPS query regardless of rate limit (e.g. on app foreground).
    function forceRefresh() as Lang.Boolean {
        _lastRefreshTimer = 0;
        return refresh();
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

    private function _tryManual() as Lang.Boolean {
        try {
            var config = new TimeConfiguration();
            var lat = config.getManualLatitude();
            var lon = config.getManualLongitude();
            if ((lat != 0.0 || lon != 0.0) &&
                LocationValidator.isValidLatitude(lat) &&
                LocationValidator.isValidLongitude(lon)) {
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
