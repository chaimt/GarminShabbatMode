using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;

class TimeInfo {

    private var _currentTime as Moment?;
    private var _timezone as String;
    private var _timezoneOffset as Number;
    private var _isDST as Boolean;
    private var _lastUpdated as Moment?;
    private var _autoUpdate as Boolean;

    function initialize() {
        _currentTime = null;
        _timezone = "UTC";
        _timezoneOffset = 0;
        _isDST = false;
        _lastUpdated = null;
        _autoUpdate = true;
    }

    function initialize(time as Moment, timezone as String, offset as Number) {
        _currentTime = time;
        _timezone = timezone;
        _timezoneOffset = offset;
        _isDST = false;
        _lastUpdated = time;
        _autoUpdate = true;
    }

    // Update current time
    function updateCurrentTime() as Void {
        _currentTime = Time.now();
        _lastUpdated = _currentTime;
    }

    function setCurrentTime(time as Moment) as Void {
        _currentTime = time;
        _lastUpdated = time;
    }

    function getCurrentTime() as Moment? {
        if (_autoUpdate || _currentTime == null) {
            updateCurrentTime();
        }
        return _currentTime;
    }

    // Timezone management
    function setTimezone(timezone as String, offset as Number, isDST as Boolean) as Void {
        _timezone = timezone;
        _timezoneOffset = offset;
        _isDST = isDST;
    }

    function getTimezone() as String {
        return _timezone;
    }

    function getTimezoneOffset() as Number {
        return _timezoneOffset;
    }

    function isDaylightSavingTime() as Boolean {
        return _isDST;
    }

    function setDaylightSavingTime(isDST as Boolean) as Void {
        _isDST = isDST;
    }

    // Time formatting and conversion
    function getGregorianInfo() as Gregorian.Info? {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            return Gregorian.info(currentTime, Time.FORMAT_MEDIUM);
        }
        return null;
    }

    function getFormattedTime(format as Number) as String {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var info = Gregorian.info(currentTime, Time.FORMAT_SHORT);
            return formatTimeInfo(info, format);
        }
        return "--:--:--";
    }

    function getFormattedDate() as String {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var info = Gregorian.info(currentTime, Time.FORMAT_SHORT);
            return formatDateInfo(info);
        }
        return "--/--/----";
    }

    // Time calculations
    function addSeconds(seconds as Number) as Moment? {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var duration = new Time.Duration(seconds);
            return currentTime.add(duration);
        }
        return null;
    }

    function addMinutes(minutes as Number) as Moment? {
        return addSeconds(minutes * 60);
    }

    function addHours(hours as Number) as Moment? {
        return addSeconds(hours * 3600);
    }

    function subtractSeconds(seconds as Number) as Moment? {
        return addSeconds(-seconds);
    }

    function subtractMinutes(minutes as Number) as Moment? {
        return addSeconds(-minutes * 60);
    }

    // Time comparison
    function isAfter(otherTime as Moment) as Boolean {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            return currentTime.greaterThan(otherTime);
        }
        return false;
    }

    function isBefore(otherTime as Moment) as Boolean {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            return currentTime.lessThan(otherTime);
        }
        return false;
    }

    function getDifferenceInSeconds(otherTime as Moment) as Number? {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var duration = currentTime.subtract(otherTime);
            return duration.value();
        }
        return null;
    }

    function getDifferenceInMinutes(otherTime as Moment) as Number? {
        var seconds = getDifferenceInSeconds(otherTime);
        if (seconds != null) {
            return (seconds / 60).toNumber();
        }
        return null;
    }

    // Time validation
    function isValid() as Boolean {
        return _currentTime != null;
    }

    function isStale(maxAgeSeconds as Number) as Boolean {
        if (_lastUpdated == null) {
            return true;
        }

        var now = Time.now();
        var age = now.subtract(_lastUpdated).value();
        return age > maxAgeSeconds;
    }

    // Auto-update control
    function setAutoUpdate(autoUpdate as Boolean) as Void {
        _autoUpdate = autoUpdate;
    }

    function isAutoUpdateEnabled() as Boolean {
        return _autoUpdate;
    }

    // State information
    function getLastUpdated() as Moment? {
        return _lastUpdated;
    }

    function getAgeInSeconds() as Number {
        if (_lastUpdated != null) {
            var now = Time.now();
            return now.subtract(_lastUpdated).value();
        }
        return -1;
    }

    // Private helper methods
    private function formatTimeInfo(info as Gregorian.Info, format as Number) as String {
        // Different time format options
        switch (format) {
            case 12: // 12-hour format
                var hour12 = info.hour;
                var ampm = "AM";
                if (hour12 == 0) {
                    hour12 = 12;
                } else if (hour12 > 12) {
                    hour12 -= 12;
                    ampm = "PM";
                } else if (hour12 == 12) {
                    ampm = "PM";
                }
                return Lang.format("$1$:$2$:$3$ $4$", [
                    hour12.format("%d"),
                    info.min.format("%02d"),
                    info.sec.format("%02d"),
                    ampm
                ]);

            case 24: // 24-hour format
            default:
                return Lang.format("$1$:$2$:$3$", [
                    info.hour.format("%02d"),
                    info.min.format("%02d"),
                    info.sec.format("%02d")
                ]);
        }
    }

    private function formatDateInfo(info as Gregorian.Info) as String {
        return Lang.format("$1$/$2$/$3$", [
            info.day.format("%02d"),
            info.month.format("%02d"),
            info.year.format("%04d")
        ]);
    }

    // Create TimeInfo instances for specific moments
    static function fromMoment(moment as Moment) as TimeInfo {
        var timeInfo = new TimeInfo();
        timeInfo.setCurrentTime(moment);
        return timeInfo;
    }

    static function now() as TimeInfo {
        var timeInfo = new TimeInfo();
        timeInfo.updateCurrentTime();
        return timeInfo;
    }

    // Export for debugging/storage
    function toDict() as Dictionary<String, Object> {
        return {
            "timestamp" => _currentTime != null ? _currentTime.value() : 0,
            "timezone" => _timezone,
            "timezone_offset" => _timezoneOffset,
            "is_dst" => _isDST,
            "last_updated" => _lastUpdated != null ? _lastUpdated.value() : 0,
            "auto_update" => _autoUpdate
        } as Dictionary<String, Object>;
    }
}