using Toybox.Lang;

// Manages Shabbat battery conservation mode.
//
// During the Shabbat period (Friday sunset → Saturday nightfall), the app
// reduces its internal activity to preserve battery life:
//   - Screen refresh rate drops from 1 s to 30 s (97% reduction, ≥80% per SC-005)
//   - GPS polling interval extends to 30 minutes (SC-006)
//
// System-level Do Not Disturb is never activated (FR-010, SC-007).
// Conservation mode exits automatically when Shabbat ends (FR-011).
class BatteryConservationService {

    // Refresh intervals
    const NORMAL_REFRESH_MS       = 1000;   // 1 second
    const CONSERVATION_REFRESH_MS = 30000;  // 30 seconds (97% reduction)

    // GPS poll intervals
    const NORMAL_GPS_INTERVAL_S       = 300;   // 5 minutes
    const CONSERVATION_GPS_INTERVAL_S = 1800;  // 30 minutes

    private var _shabbatService as ShabbatWindowService;
    private var _locationService as LocationService?;
    private var _lastActiveState as Lang.Boolean;
    private var _logger as Logger?;

    // locationService is optional; when provided, its GPS interval is adjusted
    // automatically on Shabbat transitions.
    function initialize(
        shabbatService as ShabbatWindowService,
        locationService as LocationService?
    ) {
        _shabbatService  = shabbatService;
        _locationService = locationService;
        _lastActiveState = false;

        try {
            _logger = new Logger();
        } catch (ex instanceof Lang.Exception) {
            _logger = null;
        }
    }

    // Returns true when Shabbat battery conservation mode is currently active.
    function isActive() as Lang.Boolean {
        return _shabbatService.isShabbat();
    }

    // Screen refresh interval in milliseconds for the current mode.
    function getRefreshIntervalMs() as Lang.Number {
        return isActive() ? CONSERVATION_REFRESH_MS : NORMAL_REFRESH_MS;
    }

    // GPS poll interval in seconds for the current mode.
    function getGpsIntervalSeconds() as Lang.Number {
        return isActive() ? CONSERVATION_GPS_INTERVAL_S : NORMAL_GPS_INTERVAL_S;
    }

    // Detects Shabbat transitions and applies side-effects (GPS interval change).
    // Must be called periodically (e.g. each timer tick in MainView).
    // Returns true if the active state changed since the last call; the caller
    // should restart its display timer with the new refresh interval.
    function update() as Lang.Boolean {
        var current = isActive();
        if (current == _lastActiveState) {
            return false;
        }

        _lastActiveState = current;
        _applyGpsInterval(current);

        if (_logger != null) {
            if (current) {
                _logger.info("BatteryConservation: ACTIVE - Shabbat started; refresh=" +
                    CONSERVATION_REFRESH_MS + "ms, GPS=" + CONSERVATION_GPS_INTERVAL_S + "s");
            } else {
                _logger.info("BatteryConservation: INACTIVE - Shabbat ended; restoring normal activity");
            }
        }

        return true;
    }

    // Sync _lastActiveState with the real state without reporting a change.
    // Call this once during initialization so the first update() call does not
    // incorrectly report a false→true transition when Shabbat is already active.
    function syncState() as Void {
        _lastActiveState = isActive();
        _applyGpsInterval(_lastActiveState);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private function _applyGpsInterval(conservationActive as Lang.Boolean) as Void {
        if (_locationService != null) {
            var interval = conservationActive
                ? CONSERVATION_GPS_INTERVAL_S
                : NORMAL_GPS_INTERVAL_S;
            _locationService.setUpdateIntervalSeconds(interval);
        }
    }
}
