using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

// Displays the current local time as "HH:MM" — seconds are never shown.
class ClockComponent extends BaseComponent {

    private var _fontType;  // Graphics.FontDefinition constant (e.g. FONT_LARGE)

    function initialize(x as Lang.Number, y as Lang.Number, width as Lang.Number, height as Lang.Number) {
        BaseComponent.initialize(x, y, width, height);
        _fontType = Graphics.FONT_LARGE;
        setTextColor(Graphics.COLOR_WHITE);
    }

    // Dim colour during Shabbat conservation mode.
    function setShabbatMode(isShabbat as Lang.Boolean) as Void {
        setTextColor(isShabbat ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE);
    }

    function setFont(fontType) as Void {
        _fontType = fontType;
    }

    // Returns the formatted time string for external use.
    function getTimeString() as Lang.String {
        return TimeFormatter.currentTimeHHMM();
    }

    protected function drawContent(dc as Graphics.Dc) as Void {
        var timeStr = getTimeString();
        dc.setColor(getTextColor(), Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            getX() + getWidth() / 2,
            getY() + getHeight() / 2,
            _fontType,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
