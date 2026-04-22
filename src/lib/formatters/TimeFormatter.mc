using Toybox.Lang;
using Toybox.System;

// Converts raw time values into display strings.
// All methods are stateless and safe to call from any context.
class TimeFormatter {

    // Format local seconds-from-midnight (0–86399) as "HH:MM".
    static function secondsToHHMM(localSeconds as Lang.Number) as Lang.String {
        var s = localSeconds;
        while (s < 0)     { s += 86400; }
        while (s >= 86400) { s -= 86400; }
        var h = s / 3600;
        var m = (s % 3600) / 60;
        return Lang.format("$1$:$2$", [h.format("%02d"), m.format("%02d")]);
    }

    // Format local seconds-from-midnight as "HH:MM:SS".
    static function secondsToHHMMSS(localSeconds as Lang.Number) as Lang.String {
        var s = localSeconds;
        while (s < 0)     { s += 86400; }
        while (s >= 86400) { s -= 86400; }
        var h = s / 3600;
        var m = (s % 3600) / 60;
        var sec = s % 60;
        return Lang.format("$1$:$2$:$3$", [h.format("%02d"), m.format("%02d"), sec.format("%02d")]);
    }

    // Format a total-seconds duration (e.g. countdown) as "Xd HH:MM" or "HH:MM".
    static function secondsToDuration(totalSeconds as Lang.Number) as Lang.String {
        var s = totalSeconds;
        if (s < 0) { s = 0; }
        var days = s / 86400;
        var remaining = s % 86400;
        var hours = remaining / 3600;
        var minutes = (remaining % 3600) / 60;
        if (days > 0) {
            return Lang.format("$1$d $2$:$3$", [days.format("%d"), hours.format("%02d"), minutes.format("%02d")]);
        }
        return Lang.format("$1$:$2$", [hours.format("%02d"), minutes.format("%02d")]);
    }

    // Get today's local clock as seconds from midnight.
    static function currentLocalSeconds() as Lang.Number {
        var clock = System.getClockTime();
        return clock.hour * 3600 + clock.min * 60 + clock.sec;
    }

    // Format the current device clock as "HH:MM:SS".
    static function currentTimeHHMMSS() as Lang.String {
        var clock = System.getClockTime();
        return Lang.format("$1$:$2$:$3$", [
            clock.hour.format("%02d"),
            clock.min.format("%02d"),
            clock.sec.format("%02d")
        ]);
    }

    // Format the current device clock as "HH:MM".
    static function currentTimeHHMM() as Lang.String {
        var clock = System.getClockTime();
        return Lang.format("$1$:$2$", [clock.hour.format("%02d"), clock.min.format("%02d")]);
    }

    // Placeholder string when a value is unavailable.
    static function unavailable() as Lang.String {
        return "--:--";
    }
}
