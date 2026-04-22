using Toybox.Lang;
using Toybox.System;
using Toybox.Time;

// Detects and caches the device's current UTC offset.
// Uses the difference between device-local clock and Garmin epoch modulo to
// derive the offset automatically, which handles DST without OS calls.
class TimezoneService {

    // Cached UTC offset in seconds (local = UTC + offset).
    private var _utcOffsetSeconds as Lang.Number;
    private var _lastUpdateGarminEpoch as Lang.Number;
    private var _updateIntervalSeconds as Lang.Number;
    private var _logger as Logger?;

    // Re-derive offset no more often than this many seconds (default 5 minutes).
    private const UPDATE_INTERVAL = 300;

    function initialize() {
        _utcOffsetSeconds = 0;
        _lastUpdateGarminEpoch = 0;
        _updateIntervalSeconds = UPDATE_INTERVAL;

        try {
            _logger = new Logger();
        } catch (ex instanceof Lang.Exception) {
            _logger = null;
        }

        _refresh();
    }

    // Returns the current UTC offset in seconds, refreshing if stale.
    function getUtcOffsetSeconds() as Lang.Number {
        var nowGarmin = Time.now().value();
        if (nowGarmin - _lastUpdateGarminEpoch >= _updateIntervalSeconds) {
            _refresh();
        }
        return _utcOffsetSeconds;
    }

    // Immediately re-derive the offset (e.g. after a timezone change event).
    function forceRefresh() as Void {
        _refresh();
    }

    // Returns true if the UTC offset appears to have changed since the last
    // call (useful for triggering a cache invalidation in dependent services).
    // Caller is responsible for acting on this information.
    function detectChange() as Lang.Boolean {
        var previousOffset = _utcOffsetSeconds;
        _refresh();
        return _utcOffsetSeconds != previousOffset;
    }

    // Human-readable offset string, e.g. "UTC+2" or "UTC-5".
    function getOffsetString() as Lang.String {
        var totalMinutes = _utcOffsetSeconds / 60;
        var sign = totalMinutes >= 0 ? "+" : "-";
        if (totalMinutes < 0) { totalMinutes = -totalMinutes; }
        var hours = totalMinutes / 60;
        var minutes = totalMinutes % 60;
        if (minutes == 0) {
            return Lang.format("UTC$1$$2$", [sign, hours.format("%d")]);
        }
        return Lang.format("UTC$1$$2$:$3$", [sign, hours.format("%d"), minutes.format("%02d")]);
    }

    // -------------------------------------------------------------------------
    // Private
    // -------------------------------------------------------------------------

    private function _refresh() as Void {
        try {
            var nowGarmin = Time.now().value();
            var utcSecsInDay = nowGarmin % 86400;

            var clock = System.getClockTime();
            var localSecsInDay = clock.hour * 3600 + clock.min * 60 + clock.sec;

            var offset = localSecsInDay - utcSecsInDay;
            // Clamp to realistic range [-43200, +50400] (UTC-12 to UTC+14)
            while (offset > 50400)  { offset -= 86400; }
            while (offset < -43200) { offset += 86400; }

            _utcOffsetSeconds = offset;
            _lastUpdateGarminEpoch = nowGarmin;

            if (_logger != null) {
                _logger.debug("TimezoneService: offset = " + _utcOffsetSeconds + "s");
            }
        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.warn("TimezoneService refresh failed: " + ex.getErrorMessage());
            }
        }
    }
}
