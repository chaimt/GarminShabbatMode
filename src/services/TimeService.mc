using Toybox.Time;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Timer;

class TimeService {

    private var _timeInfo as TimeInfo;
    private var _timeConfiguration as TimeConfiguration;
    private var _logger as Logger?;
    private var _updateTimer as Timer.Timer?;
    private var _isRunning as Boolean;
    private var _updateCallbacks as Array<Method>;
    private var _lastUpdate as Moment?;

    function initialize() {
        _timeInfo = new TimeInfo();
        _timeConfiguration = new TimeConfiguration();
        _logger = new Logger();
        _updateTimer = null;
        _isRunning = false;
        _updateCallbacks = [] as Array<Method>;
        _lastUpdate = null;
    }

    function initialize(configuration as TimeConfiguration) {
        _timeInfo = new TimeInfo();
        _timeConfiguration = configuration;
        _logger = new Logger();
        _updateTimer = null;
        _isRunning = false;
        _updateCallbacks = [] as Array<Method>;
        _lastUpdate = null;
    }

    // Service lifecycle
    function start() as Boolean {
        try {
            if (_isRunning) {
                return true; // Already running
            }

            // Update time immediately
            _timeInfo.updateCurrentTime();
            _lastUpdate = Time.now();

            // Start update timer
            var updateInterval = _timeConfiguration.getAutoUpdateInterval();
            _updateTimer = new Timer.Timer();
            _updateTimer.start(method(:onTimerUpdate), updateInterval * 1000, true);

            _isRunning = true;

            if (_logger != null) {
                _logger.info("TimeService started with " + updateInterval + "s interval");
            }

            return true;

        } catch (ex instanceof Exception) {
            if (_logger != null) {
                _logger.error("Failed to start TimeService: " + ex.getErrorMessage());
            }
            return false;
        }
    }

    function stop() as Void {
        try {
            if (_updateTimer != null) {
                _updateTimer.stop();
                _updateTimer = null;
            }

            _isRunning = false;

            if (_logger != null) {
                _logger.info("TimeService stopped");
            }

        } catch (ex instanceof Exception) {
            if (_logger != null) {
                _logger.error("Error stopping TimeService: " + ex.getErrorMessage());
            }
        }
    }

    function restart() as Boolean {
        stop();
        return start();
    }

    function isRunning() as Boolean {
        return _isRunning;
    }

    // Timer callback
    function onTimerUpdate() as Void {
        try {
            // Update current time
            _timeInfo.updateCurrentTime();
            _lastUpdate = Time.now();

            // Notify all registered callbacks
            notifyUpdateCallbacks();

            // Request UI update if running
            if (_isRunning) {
                WatchUi.requestUpdate();
            }

        } catch (ex instanceof Exception) {
            if (_logger != null) {
                _logger.error("Error in timer update: " + ex.getErrorMessage());
            }
        }
    }

    // Time access methods
    function getCurrentTime() as Moment? {
        return _timeInfo.getCurrentTime();
    }

    function getTimeInfo() as TimeInfo {
        return _timeInfo;
    }

    function getFormattedTime() as String {
        var format = _timeConfiguration.getTimeFormat();
        return _timeInfo.getFormattedTime(format);
    }

    function getFormattedDate() as String {
        return _timeInfo.getFormattedDate();
    }

    function getCurrentTimeString() as String {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var info = Gregorian.info(currentTime, Time.FORMAT_SHORT);

            if (_timeConfiguration.shouldShowSeconds()) {
                return Lang.format("$1$:$2$:$3$", [
                    info.hour.format("%02d"),
                    info.min.format("%02d"),
                    info.sec.format("%02d")
                ]);
            } else {
                return Lang.format("$1$:$2$", [
                    info.hour.format("%02d"),
                    info.min.format("%02d")
                ]);
            }
        }
        return "--:--:--";
    }

    function getCurrentDateString() as String {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var info = Gregorian.info(currentTime, Time.FORMAT_SHORT);
            var dateFormat = _timeConfiguration.getDateFormat();

            // Simple date formatting based on configuration
            if (dateFormat.equals("mm/dd/yyyy")) {
                return Lang.format("$1$/$2$/$3$", [
                    info.month.format("%02d"),
                    info.day.format("%02d"),
                    info.year.format("%04d")
                ]);
            } else { // Default to dd/mm/yyyy
                return Lang.format("$1$/$2$/$3$", [
                    info.day.format("%02d"),
                    info.month.format("%02d"),
                    info.year.format("%04d")
                ]);
            }
        }
        return "--/--/----";
    }

    // Time calculations
    function addMinutesToCurrentTime(minutes as Number) as Moment? {
        return _timeInfo.addMinutes(minutes);
    }

    function subtractMinutesFromCurrentTime(minutes as Number) as Moment? {
        return _timeInfo.subtractMinutes(minutes);
    }

    function getTimeDifferenceInMinutes(targetTime as Moment) as Number? {
        return _timeInfo.getDifferenceInMinutes(targetTime);
    }

    function isCurrentTimeAfter(targetTime as Moment) as Boolean {
        return _timeInfo.isAfter(targetTime);
    }

    function isCurrentTimeBefore(targetTime as Moment) as Boolean {
        return _timeInfo.isBefore(targetTime);
    }

    // Time zone management
    function getCurrentTimeZone() as String {
        return _timeInfo.getTimezone();
    }

    function setTimeZone(timezone as String, offset as Number, isDST as Boolean) as Void {
        _timeInfo.setTimezone(timezone, offset, isDST);

        if (_logger != null) {
            _logger.debug("TimeService timezone updated: " + timezone);
        }
    }

    function isDaylightSavingTime() as Boolean {
        return _timeInfo.isDaylightSavingTime();
    }

    // Configuration management
    function getConfiguration() as TimeConfiguration {
        return _timeConfiguration;
    }

    function setConfiguration(configuration as TimeConfiguration) as Void {
        _timeConfiguration = configuration;

        // Restart service if running to apply new configuration
        if (_isRunning) {
            restart();
        }
    }

    function updateConfiguration() as Void {
        // Reload configuration and restart if needed
        if (_isRunning) {
            restart();
        }
    }

    // Callback management for time updates
    function addUpdateCallback(callback as Method) as Void {
        _updateCallbacks.add(callback);
    }

    function removeUpdateCallback(callback as Method) as Boolean {
        for (var i = 0; i < _updateCallbacks.size(); i++) {
            if (_updateCallbacks[i].equals(callback)) {
                _updateCallbacks.removeAt(i);
                return true;
            }
        }
        return false;
    }

    function clearUpdateCallbacks() as Void {
        _updateCallbacks = [] as Array<Method>;
    }

    private function notifyUpdateCallbacks() as Void {
        for (var i = 0; i < _updateCallbacks.size(); i++) {
            try {
                _updateCallbacks[i].invoke();
            } catch (ex instanceof Exception) {
                if (_logger != null) {
                    _logger.warn("Update callback failed: " + ex.getErrorMessage());
                }
            }
        }
    }

    // Service status and diagnostics
    function getLastUpdateTime() as Moment? {
        return _lastUpdate;
    }

    function getUpdateInterval() as Number {
        return _timeConfiguration.getAutoUpdateInterval();
    }

    function getTimeSinceLastUpdate() as Number? {
        if (_lastUpdate != null) {
            var now = Time.now();
            return now.subtract(_lastUpdate).value();
        }
        return null;
    }

    function isTimeStale(maxAgeSeconds as Number) as Boolean {
        var age = getTimeSinceLastUpdate();
        return (age == null || age > maxAgeSeconds);
    }

    // Manual time update
    function forceUpdate() as Void {
        try {
            _timeInfo.updateCurrentTime();
            _lastUpdate = Time.now();
            notifyUpdateCallbacks();
            WatchUi.requestUpdate();

            if (_logger != null) {
                _logger.debug("TimeService force updated");
            }

        } catch (ex instanceof Exception) {
            if (_logger != null) {
                _logger.error("Error in force update: " + ex.getErrorMessage());
            }
        }
    }

    // Time formatting helpers
    function formatTimeWithFormat(time as Moment, format as Number) as String {
        var info = Gregorian.info(time, Time.FORMAT_SHORT);

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

                if (_timeConfiguration.shouldShowSeconds()) {
                    return Lang.format("$1$:$2$:$3$ $4$", [
                        hour12.format("%d"),
                        info.min.format("%02d"),
                        info.sec.format("%02d"),
                        ampm
                    ]);
                } else {
                    return Lang.format("$1$:$2$ $4$", [
                        hour12.format("%d"),
                        info.min.format("%02d"),
                        ampm
                    ]);
                }

            case 24: // 24-hour format
            default:
                if (_timeConfiguration.shouldShowSeconds()) {
                    return Lang.format("$1$:$2$:$3$", [
                        info.hour.format("%02d"),
                        info.min.format("%02d"),
                        info.sec.format("%02d")
                    ]);
                } else {
                    return Lang.format("$1$:$2$", [
                        info.hour.format("%02d"),
                        info.min.format("%02d")
                    ]);
                }
        }
    }

    // Utility methods
    function isValidTime(time as Moment?) as Boolean {
        return time != null;
    }

    function getCurrentHour() as Number {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var info = Gregorian.info(currentTime, Time.FORMAT_SHORT);
            return info.hour;
        }
        return -1;
    }

    function getCurrentMinute() as Number {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var info = Gregorian.info(currentTime, Time.FORMAT_SHORT);
            return info.min;
        }
        return -1;
    }

    function getCurrentSecond() as Number {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var info = Gregorian.info(currentTime, Time.FORMAT_SHORT);
            return info.sec;
        }
        return -1;
    }

    function getTodayMidnight() as Moment? {
        var currentTime = getCurrentTime();
        if (currentTime != null) {
            var info = Gregorian.info(currentTime, Time.FORMAT_SHORT);
            var todayOptions = {
                :year => info.year,
                :month => info.month,
                :day => info.day,
                :hour => 0,
                :minute => 0,
                :second => 0
            };
            return Gregorian.moment(todayOptions);
        }
        return null;
    }

    function getTomorrowMidnight() as Moment? {
        var midnight = getTodayMidnight();
        if (midnight != null) {
            var oneDayDuration = new Time.Duration(24 * 60 * 60); // 24 hours in seconds
            return midnight.add(oneDayDuration);
        }
        return null;
    }

    // Diagnostics and debugging
    function getServiceStatus() as Dictionary<String, Object> {
        return {
            "is_running" => _isRunning,
            "last_update" => _lastUpdate != null ? _lastUpdate.value() : 0,
            "update_interval" => getUpdateInterval(),
            "callback_count" => _updateCallbacks.size(),
            "current_time" => getCurrentTime() != null ? getCurrentTime().value() : 0,
            "timezone" => getCurrentTimeZone(),
            "is_dst" => isDaylightSavingTime()
        } as Dictionary<String, Object>;
    }
}