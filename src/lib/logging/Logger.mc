using Toybox.System;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

class Logger {

    // Log levels
    static const ERROR = 0;
    static const WARN = 1;
    static const INFO = 2;
    static const DEBUG = 3;

    private var _logLevel as Lang.Number;
    private var _enabled as Lang.Boolean;
    private var _includeTimestamp as Lang.Boolean;
    private var _prefix as Lang.String;

    function initialize() {
        _logLevel = INFO;
        _enabled = true;
        _includeTimestamp = true;
        _prefix = "ShabbatMode";
    }

    function configure(logLevel as Lang.Number, enabled as Lang.Boolean, includeTimestamp as Lang.Boolean, prefix as Lang.String) as Void {
        _logLevel = logLevel;
        _enabled = enabled;
        _includeTimestamp = includeTimestamp;
        _prefix = prefix;
    }

    function log(message as Lang.String, level as Lang.Number) as Void {
        if (!_enabled || level > _logLevel) {
            return;
        }

        var logMessage = formatLogMessage(message, level);
        System.println(logMessage);
    }

    function error(message as Lang.String) as Void {
        log(message, ERROR);
    }

    function warn(message as Lang.String) as Void {
        log(message, WARN);
    }

    function info(message as Lang.String) as Void {
        log(message, INFO);
    }

    function debug(message as Lang.String) as Void {
        log(message, DEBUG);
    }

    function setLogLevel(level as Lang.Number) as Void {
        _logLevel = level;
    }

    function getLogLevel() as Lang.Number {
        return _logLevel;
    }

    function setEnabled(enabled as Lang.Boolean) as Void {
        _enabled = enabled;
    }

    function isEnabled() as Lang.Boolean {
        return _enabled;
    }

    function setIncludeTimestamp(include as Lang.Boolean) as Void {
        _includeTimestamp = include;
    }

    function setPrefix(prefix as Lang.String) as Void {
        _prefix = prefix;
    }

    private function formatLogMessage(message as Lang.String, level as Lang.Number) as Lang.String {
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

    private function getLevelString(level as Lang.Number) as Lang.String {
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