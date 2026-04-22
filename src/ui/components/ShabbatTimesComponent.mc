using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

// Displays candle-lighting and end-of-Shabbat (Havdalah) times.
// Renders two compact labelled lines within its bounding rectangle.
class ShabbatTimesComponent extends BaseComponent {

    private var _shabbatTimeService as ShabbatTimeService?;
    private var _font as Graphics.FontReference;
    private var _labelFont as Graphics.FontReference;

    function initialize(
        x as Lang.Number,
        y as Lang.Number,
        width as Lang.Number,
        height as Lang.Number,
        service as ShabbatTimeService?
    ) {
        BaseComponent.initialize(x, y, width, height);
        _shabbatTimeService = service;
        _font      = Graphics.FONT_SMALL;
        _labelFont = Graphics.FONT_TINY;
        setTextColor(Graphics.COLOR_WHITE);
    }

    function setService(service as ShabbatTimeService) as Void {
        _shabbatTimeService = service;
    }

    function setFont(font as Graphics.FontReference) as Void {
        _font = font;
    }

    // Returns formatted candle-lighting string for external use.
    function getCandleLightingString() as Lang.String {
        if (_shabbatTimeService == null) {
            return TimeFormatter.unavailable();
        }
        var times = _shabbatTimeService.getShabbatTimes();
        if (times == null || !times.hasCandleLighting()) {
            return TimeFormatter.unavailable();
        }
        return TimeFormatter.secondsToHHMM(times.getCandleLightingLocalSeconds());
    }

    // Returns formatted end-of-Shabbat string for external use.
    function getShabbatEndString() as Lang.String {
        if (_shabbatTimeService == null) {
            return TimeFormatter.unavailable();
        }
        var times = _shabbatTimeService.getShabbatTimes();
        if (times == null || !times.hasShabbatEnd()) {
            return TimeFormatter.unavailable();
        }
        return TimeFormatter.secondsToHHMM(times.getShabbatEndLocalSeconds());
    }

    protected function drawContent(dc as Graphics.Dc) as Void {
        var cx       = getX() + getWidth() / 2;
        var halfH    = getHeight() / 2;
        var candleY  = getY() + halfH / 2;
        var endY     = getY() + halfH + halfH / 2;

        // Candle lighting row
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, candleY, _font,
            (WatchUi.loadResource(Rez.Strings.CandleLightingLabel) as Lang.String) + ": " + getCandleLightingString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // End of Shabbat row
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, endY, _font,
            (WatchUi.loadResource(Rez.Strings.HavdalahLabel) as Lang.String) + ": " + getShabbatEndString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
