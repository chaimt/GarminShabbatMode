using Toybox.Lang;
using Toybox.Math;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.System;

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
            // No reliable sunrise/sunset at extreme latitudes
            var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            data.configure(lat, lon, dayId, -1, -1, true);
        } else {
            var sunsetUtc  = SunCalculator.calculateSunsetUTC(lat, lon, n);
            var sunriseUtc = _calculateSunriseUTC(lat, lon, n);

            var sunsetLocal  = sunsetUtc  != null ? DateMath.normaliseDay(sunsetUtc  + utcOffset) : -1;
            var sunriseLocal = sunriseUtc != null ? DateMath.normaliseDay(sunriseUtc + utcOffset) : -1;

            var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            data.configure(lat, lon, dayId, sunriseLocal, sunsetLocal, false);

            if (_logger != null) {
                _logger.info("AstronomicalService: sunrise=" + sunriseLocal + "s, sunset=" + sunsetLocal + "s");
            }
        }

        _currentData = data;
        _calculationCache.store(dayId, data);
    }

    // Sunrise is symmetric with sunset around solar noon.
    // H is the same as for sunset; sunrise = noon - 4*H minutes.
    private function _calculateSunriseUTC(lat as Lang.Float, lon as Lang.Float, n as Lang.Float) as Lang.Number? {
        var t = n / 36525.0;

        var L0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
        L0 = L0 - Math.floor(L0 / 360.0) * 360.0;

        var M = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
        M = M - Math.floor(M / 360.0) * 360.0;
        var Mrad = Math.toRadians(M);

        var C = (1.914602 - 0.004817 * t - 0.000014 * t * t) * Math.sin(Mrad)
              + (0.019993 - 0.000101 * t) * Math.sin(2.0 * Mrad)
              + 0.000289 * Math.sin(3.0 * Mrad);

        var sunLon = L0 + C;
        var omegaRad = Math.toRadians(125.04 - 1934.136 * t);
        var lambda = sunLon - 0.00569 - 0.00478 * Math.sin(omegaRad);

        var epsilonBase = 23.0 + (26.0 + (21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813))) / 60.0) / 60.0;
        var epsilon = epsilonBase + 0.00256 * Math.cos(omegaRad);
        var epsilonRad = Math.toRadians(epsilon);

        var delta = Math.asin(Math.sin(epsilonRad) * Math.sin(Math.toRadians(lambda)));

        var e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);

        var L0rad = Math.toRadians(L0);
        var tanHalfEps = Math.tan(epsilonRad / 2.0);
        var y = tanHalfEps * tanHalfEps;
        var EqTime = 4.0 * Math.toDegrees(
            y * Math.sin(2.0 * L0rad)
            - 2.0 * e * Math.sin(Mrad)
            + 4.0 * e * y * Math.sin(Mrad) * Math.cos(2.0 * L0rad)
            - 0.5 * y * y * Math.sin(4.0 * L0rad)
            - 1.25 * e * e * Math.sin(2.0 * Mrad)
        );

        var latRad = Math.toRadians(lat);
        var cosH = (Math.sin(Math.toRadians(-0.8333)) - Math.sin(latRad) * Math.sin(delta))
                 / (Math.cos(latRad) * Math.cos(delta));

        if (cosH > 1.0 || cosH < -1.0) {
            return null; // Polar
        }

        var H = Math.toDegrees(Math.acos(cosH));
        var solarNoon = 720.0 - 4.0 * lon - EqTime;

        // Sunrise = noon - H (in minutes)
        var sunriseMinutes = solarNoon - 4.0 * H;
        sunriseMinutes = sunriseMinutes - Math.floor(sunriseMinutes / 1440.0) * 1440.0;

        return (sunriseMinutes * 60.0).toNumber();
    }
}
