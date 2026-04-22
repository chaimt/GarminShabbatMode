using Toybox.Lang;
using Toybox.Math;
using Toybox.Position;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.System;
using Toybox.WatchUi;

// Computes daily sunrise and sunset times using the NOAA simplified solar
// position algorithm (same as SunCalculator).  Results are accurate to ±2
// minutes at typical latitudes (FR-002, FR-003, SC-002).
//
// Calculations are cached per calendar day and per location to minimise
// repeated computation (performance requirement: <500ms, SC-004).
class AstronomicalService {

    private var _locationService as LocationService;
    private var _calculationCache as CalculationCache;
    private var _timezoneService as TimezoneService;
    private var _currentData as AstronomicalData?;
    private var _logger as Logger?;

    function initialize() {
        _locationService  = new LocationService();
        _calculationCache = new CalculationCache();
        _timezoneService  = new TimezoneService();
        _currentData      = null;

        try {
            _logger = new Logger();
        } catch (ex instanceof Lang.Exception) {
            _logger = null;
        }
    }

    // Refresh location and recompute if the day or location has changed.
    function refresh() as Void {
        _locationService.refresh();
        _ensureCalculated();
    }

    // Actively enable GPS hardware (LOCATION_ONE_SHOT).
    // When a fix arrives, _onGpsLocationUpdate() is called automatically,
    // which updates the location, clears stale cache, and requests a redraw.
    function startGpsTracking() as Void {
        _locationService.startGpsTracking(method(:_onGpsLocationUpdate));
    }

    // Stop active GPS tracking and release the radio.
    function stopGpsTracking() as Void {
        _locationService.stopGpsTracking();
    }

    // True while a LOCATION_ONE_SHOT request is outstanding.
    function isGpsTracking() as Lang.Boolean {
        return _locationService.isGpsTracking();
    }

    // GPS callback delivered by Position.enableLocationEvents().
    // Updates location, persists to cache, invalidates stale day data,
    // recomputes sunrise/sunset, and requests an immediate UI refresh.
    function _onGpsLocationUpdate(info as Position.Info) as Void {
        try {
            if (info == null || info.position == null) {
                return;
            }
            var coords = info.position.toDegrees();
            if (coords == null || coords.size() < 2) {
                return;
            }
            var lat = coords[0].toFloat();
            var lon = coords[1].toFloat();
            if (!LocationValidator.isValidLatitude(lat) ||
                !LocationValidator.isValidLongitude(lon) ||
                (lat == 0.0 && lon == 0.0)) {
                return;
            }

            _locationService.setLocation(lat, lon);
            new LocationCache().save(lat, lon);
            _calculationCache.clear();
            _ensureCalculated();

            if (_logger != null) {
                _logger.info("AstronomicalService: GPS fix received " + lat + ", " + lon);
            }
            WatchUi.requestUpdate();
        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.warn("AstronomicalService: GPS callback error - " + ex.getErrorMessage());
            }
        }
    }

    // True when astronomical data is available for today.
    function hasData() as Lang.Boolean {
        _ensureCalculated();
        return _currentData != null && !_currentData.isUnusable();
    }

    // Return today's AstronomicalData (may be null if location unavailable).
    function getAstronomicalData() as AstronomicalData? {
        _ensureCalculated();
        return _currentData;
    }

    function hasLocation() as Lang.Boolean {
        return _locationService.hasLocation();
    }

    // -------------------------------------------------------------------------
    // Private
    // -------------------------------------------------------------------------

    private function _ensureCalculated() as Void {
        var dayId = DateMath.todayDayId();

        // Use cache if valid for today and current location.
        var cachedData = _calculationCache.get(dayId);
        if (cachedData != null) {
            _currentData = cachedData;
            return;
        }

        if (!_locationService.hasLocation()) {
            _locationService.refresh();
        }

        if (!_locationService.hasLocation()) {
            _currentData = null;
            return;
        }

        var lat = _locationService.getLatitude();
        var lon = _locationService.getLongitude();
        var nowGarmin = Time.now().value();
        var n = SunCalculator.nFromGarminEpoch(nowGarmin);
        var utcOffset = _timezoneService.getUtcOffsetSeconds();
        var isPolar = LocationValidator.isPolarRegion(lat);

        var data = new AstronomicalData();

        if (isPolar) {
            data.configure(lat, lon, dayId, -1, -1, true);
        } else {
            var sunsetUtc  = SunCalculator.calculateSunsetAtZenithUTC(lat, lon, n, GEOMETRIC_ZENITH + 0.8333f);
            var sunriseUtc = SunCalculator.calculateSunriseAtZenithUTC(lat, lon, n, GEOMETRIC_ZENITH + 0.8333f);

            var sunsetLocal  = sunsetUtc  != null ? DateMath.normaliseDay(sunsetUtc  + utcOffset) : -1;
            var sunriseLocal = sunriseUtc != null ? DateMath.normaliseDay(sunriseUtc + utcOffset) : -1;

            data.configure(lat, lon, dayId, sunriseLocal, sunsetLocal, false);

            if (_logger != null) {
                _logger.info("AstronomicalService: sunrise=" + sunriseLocal + "s, sunset=" + sunsetLocal + "s");
            }
        }

        _currentData = data;
        _calculationCache.store(dayId, data);
    }

}
