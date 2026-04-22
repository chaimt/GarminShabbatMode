using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;

// Primary display view showing:
//   • Current time (live, 1-second updates)
//   • Sunrise / Sunset times for today's location
//   • Candle lighting time (configurable minutes before sunset)
//   • End of Shabbat / Havdalah time (configurable minutes after sunset)
class TimeDisplayView extends WatchUi.View {

    private var _shabbatService as ShabbatWindowService?;
    private var _astronomicalService as AstronomicalService?;
    private var _timezoneService as TimezoneService?;
    private var _logger as Logger?;
    private var _updateTimer as Timer.Timer?;
    private var _initialized as Lang.Boolean;
    private var _tickCount as Lang.Number;

    // Layout constants (set during first draw based on screen size)
    private var _screenWidth as Lang.Number;
    private var _screenHeight as Lang.Number;
    private var _layoutReady as Lang.Boolean;

    function initialize() {
        View.initialize();
        _initialized = false;
        _layoutReady = false;
        _screenWidth = 240;
        _screenHeight = 240;
        _tickCount = 0;

        try {
            _logger = new Logger();
            _shabbatService = new ShabbatWindowService();
            _astronomicalService = new AstronomicalService();
            _timezoneService = new TimezoneService();
            _initialized = true;
            if (_logger != null) {
                _logger.info("TimeDisplayView initialized");
            }
        } catch (ex instanceof Lang.Exception) {
            _initialized = false;
            System.println("TimeDisplayView init failed: " + ex.getErrorMessage());
        }
    }

    // Start 1-second refresh timer when the view becomes active.
    function onShow() as Void {
        if (_updateTimer == null) {
            _updateTimer = new Timer.Timer();
        }
        _updateTimer.start(method(:onTick), 1000, true);
        if (_astronomicalService != null) {
            _astronomicalService.refresh();
        }
    }

    // Stop timer when the view is hidden to preserve battery.
    function onHide() as Void {
        if (_updateTimer != null) {
            _updateTimer.stop();
        }
    }

    function onTick() as Void {
        _tickCount++;
        // Every 60 ticks (~1 minute): check for timezone change and refresh astro data.
        if (_tickCount >= 60) {
            _tickCount = 0;
            if (_timezoneService != null && _timezoneService.detectChange()) {
                // Timezone changed — invalidate cached calculations.
                if (_astronomicalService != null) {
                    _astronomicalService.refresh();
                }
                if (_logger != null) {
                    _logger.info("TimeDisplayView: timezone change detected, refreshed");
                }
            }
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        try {
            _screenWidth = dc.getWidth();
            _screenHeight = dc.getHeight();

            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();

            if (!_initialized) {
                _drawError(dc);
                return;
            }

            _drawAllRows(dc);

        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.error("TimeDisplayView.onUpdate: " + ex.getErrorMessage());
            }
            _drawError(dc);
        }
    }

    // -------------------------------------------------------------------------
    // Drawing
    // -------------------------------------------------------------------------

    // Lay out 5 rows evenly across the screen height.
    //
    //  Row 0 – label "Shabbat" or "ShabbatMode"  (small, top)
    //  Row 1 – current time HH:MM:SS              (large, prominent)
    //  Row 2 – Sunrise / Sunset pair              (small)
    //  Row 3 – Candle lighting                    (small)
    //  Row 4 – Shabbat ends                       (small)
    private function _drawAllRows(dc as Graphics.Dc) as Void {
        var w  = _screenWidth;
        var h  = _screenHeight;
        var cx = w / 2;

        // Row vertical centres (distribute across the screen)
        var row0Y = h / 9;
        var row1Y = h * 3 / 9;
        var row2Y = h * 5 / 9;
        var row3Y = h * 7 / 9;
        var row4Y = h * 8 / 9;

        var isShabbat = (_shabbatService != null && _shabbatService.isShabbat());

        // ── Row 0: App / mode label ──────────────────────────────────────────
        var modeLabel = isShabbat
            ? (WatchUi.loadResource(Rez.Strings.ShabbatActive) as String)
            : (WatchUi.loadResource(Rez.Strings.AppName) as String);
        var modeColor = isShabbat ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
        dc.setColor(modeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, row0Y, Graphics.FONT_SMALL, modeLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Row 1: Current time ──────────────────────────────────────────────
        var timeStr = TimeFormatter.currentTimeHHMMSS();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, row1Y, Graphics.FONT_LARGE, timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Row 2: Sunrise / Sunset ──────────────────────────────────────────
        var sunriseStr = TimeFormatter.unavailable();
        var sunsetStr  = TimeFormatter.unavailable();

        if (_astronomicalService != null && _astronomicalService.hasData()) {
            var data = _astronomicalService.getAstronomicalData();
            if (data != null) {
                if (data.hasSunrise()) {
                    sunriseStr = TimeFormatter.secondsToHHMM(data.getSunriseLocalSeconds());
                }
                if (data.hasSunset()) {
                    sunsetStr = TimeFormatter.secondsToHHMM(data.getSunsetLocalSeconds());
                }
            }
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var sunRow = Lang.format("$1$ \u2191  $2$ \u2193", [sunriseStr, sunsetStr]);
        dc.drawText(cx, row2Y, Graphics.FONT_SMALL, sunRow,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Row 3: Candle lighting ───────────────────────────────────────────
        var candleStr = TimeFormatter.unavailable();
        if (_astronomicalService != null && _astronomicalService.hasData()) {
            var config = new TimeConfiguration();
            var offset = config.getCandleLightingOffset();
            var data = _astronomicalService.getAstronomicalData();
            if (data != null && data.hasSunset()) {
                var candleSecs = data.getSunsetLocalSeconds() - offset * 60;
                candleStr = TimeFormatter.secondsToHHMM(candleSecs);
            }
        }
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, row3Y, Graphics.FONT_SMALL,
            (WatchUi.loadResource(Rez.Strings.CandleLightingLabel) as String) + ": " + candleStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Row 4: End of Shabbat ────────────────────────────────────────────
        var endStr = TimeFormatter.unavailable();
        if (_shabbatService != null) {
            var nightfall = _shabbatService.getNightfallTimeString();
            if (!nightfall.equals("") && !nightfall.equals("00:00")) {
                endStr = nightfall;
            }
        }
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, row4Y, Graphics.FONT_TINY,
            (WatchUi.loadResource(Rez.Strings.HavdalahLabel) as String) + ": " + endStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Location / data quality indicator ────────────────────────────────
        if (_shabbatService != null && !_shabbatService.hasLocation()) {
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h - h / 14, Graphics.FONT_TINY,
                WatchUi.loadResource(Rez.Strings.LocationNeeded) as String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (_astronomicalService != null && _astronomicalService.hasData()) {
            var data = _astronomicalService.getAstronomicalData();
            if (data != null && data.isPolarRegion()) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, h - h / 14, Graphics.FONT_TINY,
                    WatchUi.loadResource(Rez.Strings.PolarWarning) as String,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
    }

    private function _drawError(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_screenWidth / 2, _screenHeight / 2, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.TimeDisplayError) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // -------------------------------------------------------------------------
    // Public accessors for delegate
    // -------------------------------------------------------------------------

    function isInitialized() as Lang.Boolean {
        return _initialized;
    }
}

// Input delegate for TimeDisplayView — pressing SELECT navigates to settings.
class TimeDisplayDelegate extends WatchUi.BehaviorDelegate {

    private var _view as TimeDisplayView;

    function initialize(view as TimeDisplayView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Lang.Boolean {
        try {
            var settingsView = new TimeSettingsView();
            var settingsDelegate = new TimeSettingsDelegate(settingsView);
            WatchUi.pushView(settingsView, settingsDelegate, WatchUi.SLIDE_LEFT);
        } catch (ex instanceof Lang.Exception) {
            // If settings view fails, do nothing
        }
        return true;
    }

    function onBack() as Lang.Boolean {
        return false;
    }

    function onMenu() as Lang.Boolean {
        return onSelect();
    }
}
