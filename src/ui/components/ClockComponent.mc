using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

// Displays the current local time as "HH:MM:SS" (or "HH:MM" when compact).
// During Shabbat, seconds are always suppressed: setShabbatMode(true) must be
// called by any parent view that knows Shabbat is active (T092 / FR-012).
class ClockComponent extends BaseComponent {

    private var _showSeconds as Lang.Boolean;
    private var _font as Graphics.FontReference;

    function initialize(x as Lang.Number, y as Lang.Number, width as Lang.Number, height as Lang.Number) {
        BaseComponent.initialize(x, y, width, height);
        _showSeconds = true;
        _font = Graphics.FONT_LARGE;
        setTextColor(Graphics.COLOR_WHITE);
    }

    // Convenience wrapper: suppress seconds and dim colour during Shabbat.
    // Call with isShabbat=true when BatteryConservationService.isActive() is true.
    function setShabbatMode(isShabbat as Lang.Boolean) as Void {
        _showSeconds = !isShabbat;
        setTextColor(isShabbat ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE);
    }

    function setShowSeconds(show as Lang.Boolean) as Void {
        _showSeconds = show;
    }

    function setFont(font as Graphics.FontReference) as Void {
        _font = font;
    }

    // Returns the formatted time string for external use.
    function getTimeString() as Lang.String {
        if (_showSeconds) {
            return TimeFormatter.currentTimeHHMMSS();
        }
        return TimeFormatter.currentTimeHHMM();
    }

    protected function drawContent(dc as Graphics.Dc) as Void {
        var timeStr = getTimeString();
        dc.setColor(getTextColor(), Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            getX() + getWidth() / 2,
            getY() + getHeight() / 2,
            _font,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
