using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;

class TimeInfo {

    private var _currentTime as Time.Moment?;
    private var _timezone as Lang.String;
    private var _timezoneOffset as Lang.Number;
    private var _isDST as Lang.Boolean;
    private var _lastUpdated as Time.Moment?;
    private var _autoUpdate as Lang.Boolean;

    function initialize() {
        _currentTime = null;
        _timezone = "UTC";
        _timezoneOffset = 0;
        _isDST = false;
        _lastUpdated = null;
        _autoUpdate = true;
    }

    function configure(time as Time.Moment, timezone as Lang.String, offset as Lang.Number) as Void {
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

    function setCurrentTime(time as Time.Moment) as Void {
        _currentTime = time;
        _lastUpdated = time;
    }

    function getCurrentTime() as Time.Moment? {
        if (_autoUpdate || _currentTime == null) {
            updateCurrentTime();
        }
        return _currentTime;
    }

    // Timezone management
    function setTimezone(timezone as Lang.String, offset as Lang.Number, isDST as Lang.Boolean) as Void {
        _timezone = timezone;
        _timezoneOffset = offset;
        _isDST = isDST;
    }

    function getTimezone() as Lang.String {
        return _timezone;
    }

    function getTimezoneOffset() as Lang.Number {
        return _timezoneOffset;
    }

    function isDaylightSavingTime() as Lang.Boolean {
        return _isDST;
    }

    function setDaylightSavingTime(isDST as Lang.Boolean) as Void {
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

    function getFormattedTime(format as Lang.Number) as Lang.String {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var info = Gregorian.info(currentTime, Time.FORMAT_SHORT);
            return formatTimeInfo(info, format);
        }
        return "--:--:--";
    }

    function getFormattedDate() as Lang.String {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var info = Gregorian.info(currentTime, Time.FORMAT_SHORT);
            return formatDateInfo(info);
        }
        return "--/--/----";
    }

    // Time calculations
    function addSeconds(seconds as Lang.Number) as Time.Moment? {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var duration = new Time.Duration(seconds);
            return currentTime.add(duration);
        }
        return null;
    }

    function addMinutes(minutes as Lang.Number) as Time.Moment? {
        return addSeconds(minutes * 60);
    }

    function addHours(hours as Lang.Number) as Time.Moment? {
        return addSeconds(hours * 3600);
    }

    function subtractSeconds(seconds as Lang.Number) as Time.Moment? {
        return addSeconds(-seconds);
    }

    function subtractMinutes(minutes as Lang.Number) as Time.Moment? {
        return addSeconds(-minutes * 60);
    }

    // Time comparison
    function isAfter(otherTime as Time.Moment) as Lang.Boolean {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            return currentTime.greaterThan(otherTime);
        }
        return false;
    }

    function isBefore(otherTime as Time.Moment) as Lang.Boolean {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            return currentTime.lessThan(otherTime);
        }
        return false;
    }

    function getDifferenceInSeconds(otherTime as Time.Moment) as Lang.Number? {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var duration = currentTime.subtract(otherTime);
            return duration.value();
        }
        return null;
    }

    function getDifferenceInMinutes(otherTime as Time.Moment) as Lang.Number? {
        var seconds = getDifferenceInSeconds(otherTime);
        if (seconds != null) {
            return (seconds / 60).toNumber();
        }
        return null;
    }

    // Time validation
    function isValid() as Lang.Boolean {
        return _currentTime != null;
    }

    function isStale(maxAgeSeconds as Lang.Number) as Lang.Boolean {
        if (_lastUpdated == null) {
            return true;
        }

        var now = Time.now();
        var age = now.subtract(_lastUpdated).value();
        return age > maxAgeSeconds;
    }

    // Auto-update control
    function setAutoUpdate(autoUpdate as Lang.Boolean) as Void {
        _autoUpdate = autoUpdate;
    }

    function isAutoUpdateEnabled() as Lang.Boolean {
        return _autoUpdate;
    }

    // State information
    function getLastUpdated() as Time.Moment? {
        return _lastUpdated;
    }

    function getAgeInSeconds() as Lang.Number {
        if (_lastUpdated != null) {
            var now = Time.now();
            return now.subtract(_lastUpdated).value();
        }
        return -1;
    }

    // Private helper methods
    private function formatTimeInfo(info as Gregorian.Info, format as Lang.Number) as Lang.String {
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

    private function formatDateInfo(info as Gregorian.Info) as Lang.String {
        return Lang.format("$1$/$2$/$3$", [
            info.day.format("%02d"),
            info.month.format("%02d"),
            info.year.format("%04d")
        ]);
    }

    // Create TimeInfo instances for specific moments
    static function fromMoment(moment as Time.Moment) as TimeInfo {
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
    function toDict() as Lang.Dictionary<Lang.String, Lang.Object> {
        return {
            "timestamp" => _currentTime != null ? _currentTime.value() : 0,
            "timezone" => _timezone,
            "timezone_offset" => _timezoneOffset,
            "is_dst" => _isDST,
            "last_updated" => _lastUpdated != null ? _lastUpdated.value() : 0,
            "auto_update" => _autoUpdate
        } as Lang.Dictionary<Lang.String, Lang.Object>;
    }
}