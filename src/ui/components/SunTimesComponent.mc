using Toybox.Graphics;
using Toybox.Lang;

// Displays today's sunrise and sunset times side by side.
// Draws a compact two-field row: "↑ HH:MM  ↓ HH:MM"
class SunTimesComponent extends BaseComponent {

    private var _astronomicalService as AstronomicalService?;
    private var _font as Graphics.FontReference;

    function initialize(
        x as Lang.Number,
        y as Lang.Number,
        width as Lang.Number,
        height as Lang.Number,
        service as AstronomicalService?
    ) {
        BaseComponent.initialize(x, y, width, height);
        _astronomicalService = service;
        _font = Graphics.FONT_SMALL;
        setTextColor(Graphics.COLOR_LT_GRAY);
    }

    function setFont(font as Graphics.FontReference) as Void {
        _font = font;
    }

    function setAstronomicalService(service as AstronomicalService) as Void {
        _astronomicalService = service;
    }

    // Returns the formatted display string (useful for unit testing / parent views).
    function getSunTimesString() as Lang.String {
        var sunriseStr = TimeFormatter.unavailable();
        var sunsetStr  = TimeFormatter.unavailable();

        if (_astronomicalService != null && _astronomicalService.hasData()) {
            var data = _astronomicalService.getAstronomicalData();
            if (data != null) {
                if (data.isPolarRegion()) {
                    return "Polar region";
                }
                if (data.hasSunrise()) {
                    sunriseStr = TimeFormatter.secondsToHHMM(data.getSunriseLocalSeconds());
                }
                if (data.hasSunset()) {
                    sunsetStr = TimeFormatter.secondsToHHMM(data.getSunsetLocalSeconds());
                }
            }
        }
        return Lang.format("\u2191$1$  \u2193$2$", [sunriseStr, sunsetStr]);
    }

    protected function drawContent(dc as Graphics.Dc) as Void {
        var text = getSunTimesString();
        dc.setColor(getTextColor(), Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            getX() + getWidth() / 2,
            getY() + getHeight() / 2,
            _font,
            text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
