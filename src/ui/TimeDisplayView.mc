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
    private var _conservationService as BatteryConservationService?;
    private var _parashaService as ParashaService?;
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
            _parashaService = new ParashaService();
            // Conservation service: drives timer interval + seconds suppression (T090)
            _conservationService = new BatteryConservationService(_shabbatService, null);
            _conservationService.syncState();
            _initialized = true;
            if (_logger != null) {
                _logger.info("TimeDisplayView initialized");
            }
        } catch (ex instanceof Lang.Exception) {
            _initialized = false;
            System.println("TimeDisplayView init failed: " + ex.getErrorMessage());
        }
    }

    // Start refresh timer at the interval appropriate for the current conservation mode.
    // During Shabbat: 30 000 ms (30 s) — matches BatteryConservationService (SC-005, T090).
    // Outside Shabbat: 1 000 ms (1 s) — normal 1-second clock update.
    function onShow() as Void {
        if (_updateTimer == null) {
            _updateTimer = new Timer.Timer();
        }
        var intervalMs = (_conservationService != null)
            ? _conservationService.getRefreshIntervalMs()
            : 1000;
        _updateTimer.start(method(:onTick), intervalMs, true);
        if (_astronomicalService != null) {
            _astronomicalService.refresh();
            // Actively enable GPS hardware to acquire a fresh location fix (T094/T095).
            // LOCATION_ONE_SHOT turns off automatically after the first fix.
            _astronomicalService.startGpsTracking();
        }
    }

    // Stop timer and GPS when the view is hidden to preserve battery.
    function onHide() as Void {
        if (_updateTimer != null) {
            _updateTimer.stop();
        }
        if (_astronomicalService != null) {
            _astronomicalService.stopGpsTracking();
        }
    }

    function onTick() as Void {
        // Detect Shabbat transitions and restart timer at the correct interval (T090).
        if (_conservationService != null) {
            var stateChanged = _conservationService.update();
            if (stateChanged && _updateTimer != null) {
                var newInterval = _conservationService.getRefreshIntervalMs();
                _updateTimer.stop();
                _updateTimer.start(method(:onTick), newInterval, true);
                if (_logger != null) {
                    _logger.info("TimeDisplayView timer restarted: " + newInterval + "ms");
                }
            }
        }

        _tickCount++;
        // Every 60 ticks: check for timezone change and refresh astro data.
        // During conservation mode ticks are 30 s apart, so 60 ticks ≈ 30 min.
        if (_tickCount >= 60) {
            _tickCount = 0;
            if (_timezoneService != null && _timezoneService.detectChange()) {
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

    // Lay out 6 rows across the screen height.
    //
    //  Row 0 – label "Shabbat"          (small, top)
    //  Row 1 – current time HH:MM       (large, prominent)
    //  Row 2 – Sunrise / Sunset pair    (small)
    //  Row 3 – Candle lighting          (small)
    //  Row 4 – Shabbat ends             (small)
    //  Row 5 – Parashat HaShavua        (tiny, bottom)
    //          or GPS-acquiring / location-needed indicator
    private function _drawAllRows(dc as Graphics.Dc) as Void {
        var w  = _screenWidth;
        var h  = _screenHeight;
        var cx = w / 2;

        // Row vertical centres (10ths layout to fit 6 rows)
        var row0Y = h / 10;
        var row1Y = h * 3 / 10;
        var row2Y = h * 5 / 10;
        var row3Y = h * 68 / 100;
        var row4Y = h * 80 / 100;
        var row5Y = h * 91 / 100;

        var isShabbat = (_shabbatService != null && _shabbatService.isShabbat());

        // ── Row 0: App / mode label ──────────────────────────────────────────
        var modeLabel = isShabbat
            ? (WatchUi.loadResource(Rez.Strings.ShabbatActive) as Lang.String)
            : (WatchUi.loadResource(Rez.Strings.AppName) as Lang.String);
        var modeColor = isShabbat ? Graphics.COLOR_YELLOW : Graphics.COLOR_WHITE;
        dc.setColor(modeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, row0Y, Graphics.FONT_SMALL, modeLabel,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Row 1: Current time HH:MM (seconds never shown) ─────────────────
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, row1Y, Graphics.FONT_LARGE, TimeFormatter.currentTimeHHMM(),
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
            (WatchUi.loadResource(Rez.Strings.CandleLightingLabel) as Lang.String) + ": " + candleStr,
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
            (WatchUi.loadResource(Rez.Strings.HavdalahLabel) as Lang.String) + ": " + endStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── Row 5: Parashat HaShavua / location status ───────────────────────
        // Priority order:
        //   1. Manual source — no coords configured → prompt
        //   2. Manual source — coords configured → "Manual" indicator
        //   3. GPS source — GPS acquiring → "acquiring…" status
        //   4. GPS source — no location → prompt
        //   5. Polar region warning
        //   6. Normal: Parashat HaShavua
        var locConfig = new TimeConfiguration();
        var isManualMode = locConfig.getLocationSource().equals("manual");
        var hasManualCoords = LocationValidator.hasValidManualCoords(
            locConfig.getManualLatitude(), locConfig.getManualLongitude());

        if (isManualMode && !hasManualCoords) {
            // Manual mode selected but no coordinates set yet
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, row5Y, Graphics.FONT_TINY,
                WatchUi.loadResource(Rez.Strings.ManualLocNoCoords) as Lang.String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (isManualMode && hasManualCoords) {
            // Manual mode with valid coordinates — show compact indicator
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, row5Y, Graphics.FONT_TINY,
                WatchUi.loadResource(Rez.Strings.LocationIndicatorManual) as Lang.String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else if (_shabbatService != null && !_shabbatService.hasLocation()) {
            if (_astronomicalService != null && _astronomicalService.isGpsTracking()) {
                // GPS is actively acquiring a fix — reassure the user
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, row5Y, Graphics.FONT_TINY,
                    WatchUi.loadResource(Rez.Strings.GpsAcquiring) as Lang.String,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                // No location and GPS not active — prompt user to set location
                dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, row5Y, Graphics.FONT_TINY,
                    WatchUi.loadResource(Rez.Strings.LocationNeeded) as Lang.String,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } else if (_astronomicalService != null && _astronomicalService.hasData()) {
            var data = _astronomicalService.getAstronomicalData();
            if (data != null && data.isPolarRegion()) {
                dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, row5Y, Graphics.FONT_TINY,
                    WatchUi.loadResource(Rez.Strings.PolarWarning) as Lang.String,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                // Normal state: show the weekly parasha
                _drawParasha(dc, cx, row5Y);
            }
        } else {
            _drawParasha(dc, cx, row5Y);
        }
    }

    // Draw the current week's parasha name at the given position.
    private function _drawParasha(dc as Graphics.Dc, cx as Lang.Number, y as Lang.Number) as Void {
        if (_parashaService == null) {
            return;
        }
        try {
            var config   = new TimeConfiguration();
            var isIsrael = config.getRegion().equals("israel");
            var name     = _parashaService.getParashaName(isIsrael);
            if (!name.equals("--")) {
                var label = (WatchUi.loadResource(Rez.Strings.ParashaLabel) as Lang.String) + " " + name;
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, y, Graphics.FONT_TINY, label,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        } catch (ex instanceof Lang.Exception) {
            // Parasha unavailable — Row 5 stays blank
        }
    }

    private function _drawError(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_screenWidth / 2, _screenHeight / 2, Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.TimeDisplayError) as Lang.String,
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
