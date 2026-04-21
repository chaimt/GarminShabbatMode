using Toybox.System;
using Toybox.Lang;
using Toybox.Time;

class Logger {

    // Log levels
    static const ERROR = 0;
    static const WARN = 1;
    static const INFO = 2;
    static const DEBUG = 3;

    private var _logLevel as Number;
    private var _enabled as Boolean;
    private var _includeTimestamp as Boolean;
    private var _prefix as String;

    function initialize() {
        _logLevel = INFO; // Default log level
        _enabled = true;
        _includeTimestamp = true;
        _prefix = "ShabbatMode";
    }

    function initialize(logLevel as Number, enabled as Boolean, includeTimestamp as Boolean, prefix as String) {
        _logLevel = logLevel;
        _enabled = enabled;
        _includeTimestamp = includeTimestamp;
        _prefix = prefix;
    }

    function log(message as String, level as Number) as Void {
        if (!_enabled || level > _logLevel) {
            return;
        }

        var logMessage = formatLogMessage(message, level);
        System.println(logMessage);
    }

    function error(message as String) as Void {
        log(message, ERROR);
    }

    function warn(message as String) as Void {
        log(message, WARN);
    }

    function info(message as String) as Void {
        log(message, INFO);
    }

    function debug(message as String) as Void {
        log(message, DEBUG);
    }

    function setLogLevel(level as Number) as Void {
        _logLevel = level;
    }

    function getLogLevel() as Number {
        return _logLevel;
    }

    function setEnabled(enabled as Boolean) as Void {
        _enabled = enabled;
    }

    function isEnabled() as Boolean {
        return _enabled;
    }

    function setIncludeTimestamp(include as Boolean) as Void {
        _includeTimestamp = include;
    }

    function setPrefix(prefix as String) as Void {
        _prefix = prefix;
    }

    private function formatLogMessage(message as String, level as Number) as String {
        var levelString = getLevelString(level);
        var timestamp = "";

        if (_includeTimestamp) {
            var now = Time.now();
            var info = Gregorian.info(now, Time.FORMAT_SHORT);
            timestamp = Lang.format("$1$-$2$-$3$ $4$:$5$:$6$ ", [
                info.year.format("%04d"),
                info.month.format("%02d"),
                info.day.format("%02d"),
                info.hour.format("%02d"),
                info.min.format("%02d"),
                info.sec.format("%02d")
            ]);
        }

        return Lang.format("$1$[$2$] [$3$] $4$", [
            timestamp,
            _prefix,
            levelString,
            message
        ]);
    }

    private function getLevelString(level as Number) as String {
        switch (level) {
            case ERROR:
                return "ERROR";
            case WARN:
                return "WARN";
            case INFO:
                return "INFO";
            case DEBUG:
                return "DEBUG";
            default:
                return "UNKNOWN";
        }
    }
}