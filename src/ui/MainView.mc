using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using Toybox.Application;

class MainView extends WatchUi.View {

    private var _configService as ConfigService?;
    private var _shabbatService as ShabbatWindowService?;
    private var _conservationService as BatteryConservationService?;
    private var _logger as Logger?;
    private var _components as Lang.Array<BaseComponent>;
    private var _appNameComponent as TextComponent?;
    private var _timeComponent as TextComponent?;
    private var _statusComponent as TextComponent?;
    private var _updateTimer as Timer.Timer?;
    private var _currentTimerIntervalMs as Lang.Number;
    private var _initialized as Lang.Boolean;

    function initialize() {
        View.initialize();
        _components = [] as Lang.Array<BaseComponent>;
        _initialized = false;
        _updateTimer = null;
        _currentTimerIntervalMs = 1000;

        try {
            _configService = new ConfigService();
            _configService.initializeService();

            _logger = new Logger();
            _logger.info("MainView initializing");

            _shabbatService = new ShabbatWindowService();
            _conservationService = new BatteryConservationService(_shabbatService, null);
            _conservationService.syncState();

            _initialized = true;

        } catch (ex instanceof Lang.Exception) {
            _initialized = false;
            System.println("MainView initialization failed: " + ex.getErrorMessage());
        }
    }

    // Called when this View is brought to the foreground – start refresh timer
    // at the interval appropriate for the current conservation mode.
    function onShow() as Void {
        if (_logger != null) {
            _logger.debug("MainView onShow");
        }
        if (_updateTimer == null) {
            _updateTimer = new Timer.Timer();
        }
        _currentTimerIntervalMs = (_conservationService != null)
            ? _conservationService.getRefreshIntervalMs()
            : 1000;
        _updateTimer.start(method(:onTimerTick), _currentTimerIntervalMs, true);
    }

    // Called when this View leaves the screen – stop the timer to save battery.
    function onHide() as Void {
        if (_logger != null) {
            _logger.debug("MainView onHide");
        }
        if (_updateTimer != null) {
            _updateTimer.stop();
        }
    }

    // Timer callback: check for conservation-mode transitions, then redraw.
    function onTimerTick() as Void {
        if (_conservationService != null) {
            var stateChanged = _conservationService.update();
            if (stateChanged && _updateTimer != null) {
                // Shabbat started or ended – restart timer with the new interval.
                var newInterval = _conservationService.getRefreshIntervalMs();
                _updateTimer.stop();
                _updateTimer.start(method(:onTimerTick), newInterval, true);
                _currentTimerIntervalMs = newInterval;
                if (_logger != null) {
                    _logger.info("MainView timer restarted: " + newInterval + "ms");
                }
            }
        }
        WatchUi.requestUpdate();
    }

    // Redraw the screen.
    function onUpdate(dc as Graphics.Dc) as Void {
        try {
            var width = dc.getWidth();
            var height = dc.getHeight();

            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();

            if (!_initialized) {
                drawErrorScreen(dc, width, height);
                return;
            }

            if (_components.size() == 0) {
                setupComponents(width, height);
            }

            // Determine mode and update component text/colours accordingly.
            // Conservation mode (Shabbat active) uses a minimal, low-refresh layout.
            if (_conservationService != null && _conservationService.isActive()) {
                updateConservationDisplay();
            } else if (_shabbatService != null && _shabbatService.isShabbat()) {
                updateShabbatDisplay();
            } else {
                updateCountdownDisplay();
            }

            for (var i = 0; i < _components.size(); i++) {
                _components[i].draw(dc);
            }

            if (_configService != null && _configService.isFirstRun()) {
                drawFirstRunMessage(dc, width, height);
            }

        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.error("Error in MainView onUpdate: " + ex.getErrorMessage());
            }
            drawErrorScreen(dc, dc.getWidth(), dc.getHeight());
        }
    }

    // -------------------------------------------------------------------------
    // Layout setup (called once when components are first needed)
    // -------------------------------------------------------------------------

    private function setupComponents(screenWidth as Lang.Number, screenHeight as Lang.Number) as Void {
        try {
            var topY    = screenHeight / 6;
            var middleY = screenHeight / 2;
            var bottomY = screenHeight * 2 / 3;

            var appName = WatchUi.loadResource(Rez.Strings.AppName) as Lang.String;
            if (_configService != null) {
                appName = _configService.getAppName();
            }

            _appNameComponent = new TextComponent(0, topY - 20, screenWidth, 40, appName);
            _appNameComponent.setTextColor(Graphics.COLOR_WHITE);
            _appNameComponent.setFont(Graphics.FONT_MEDIUM);
            _components.add(_appNameComponent);

            _timeComponent = new TextComponent(0, middleY - 24, screenWidth, 48, "00:00:00");
            _timeComponent.setTextColor(Graphics.COLOR_WHITE);
            _timeComponent.setFont(Graphics.FONT_LARGE);
            _components.add(_timeComponent);

            _statusComponent = new TextComponent(0, bottomY - 15, screenWidth, 30, "");
            _statusComponent.setTextColor(Graphics.COLOR_LT_GRAY);
            _statusComponent.setFont(Graphics.FONT_SMALL);
            _components.add(_statusComponent);

            if (_logger != null) {
                _logger.debug("MainView components setup complete");
            }

        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.error("Error setting up MainView components: " + ex.getErrorMessage());
            }
        }
    }

    // -------------------------------------------------------------------------
    // Display modes
    // -------------------------------------------------------------------------

    // Shabbat is active: show the current time prominently.
    private function updateShabbatDisplay() as Void {
        if (_appNameComponent != null) {
            _appNameComponent.setText(WatchUi.loadResource(Rez.Strings.ShabbatActive) as Lang.String);
            _appNameComponent.setTextColor(Graphics.COLOR_YELLOW);
        }

        if (_timeComponent != null) {
            var clockTime = System.getClockTime();
            var timeString = Lang.format("$1$:$2$:$3$", [
                clockTime.hour.format("%02d"),
                clockTime.min.format("%02d"),
                clockTime.sec.format("%02d")
            ]);
            _timeComponent.setText(timeString);
            _timeComponent.setTextColor(Graphics.COLOR_WHITE);
        }

        // Show when Shabbat ends (only on Saturday)
        if (_statusComponent != null) {
            if (_shabbatService != null) {
                var endsAt = _shabbatService.getNightfallTimeString();
                _statusComponent.setText(
                    (WatchUi.loadResource(Rez.Strings.ConservationEndsPrefix) as Lang.String) + " " + endsAt
                );
            } else {
                _statusComponent.setText("");
            }
            _statusComponent.setTextColor(Graphics.COLOR_LT_GRAY);
        }
    }

    // Shabbat battery conservation mode: minimal, static-like layout.
    // Refreshes only every 30 s (≥80% reduction per SC-005).
    // Shows time without seconds; end-of-Shabbat shown in dim text (FR-012).
    private function updateConservationDisplay() as Void {
        if (_appNameComponent != null) {
            _appNameComponent.setText(WatchUi.loadResource(Rez.Strings.ShabbatActive) as Lang.String);
            _appNameComponent.setTextColor(Graphics.COLOR_DK_GRAY);
        }

        if (_timeComponent != null) {
            var clockTime = System.getClockTime();
            // Omit seconds – they would be stale for up to 30 s anyway.
            var timeString = Lang.format("$1$:$2$", [
                clockTime.hour.format("%02d"),
                clockTime.min.format("%02d")
            ]);
            _timeComponent.setText(timeString);
            _timeComponent.setTextColor(Graphics.COLOR_LT_GRAY);
        }

        if (_statusComponent != null) {
            var statusText = "";
            if (_shabbatService != null) {
                var endsAt = _shabbatService.getNightfallTimeString();
                statusText = (WatchUi.loadResource(Rez.Strings.ConservationEndsPrefix) as Lang.String) + " " + endsAt;
            }
            _statusComponent.setText(statusText);
            _statusComponent.setTextColor(Graphics.COLOR_DK_GRAY);
        }
    }

    // Shabbat is not active: show countdown to the next Shabbat.
    private function updateCountdownDisplay() as Void {
        if (_appNameComponent != null) {
            _appNameComponent.setText(WatchUi.loadResource(Rez.Strings.AppName) as Lang.String);
            _appNameComponent.setTextColor(Graphics.COLOR_WHITE);
        }

        if (_timeComponent != null) {
            var countdown = "";
            if (_shabbatService != null) {
                countdown = _shabbatService.getFormattedCountdown();
            }
            if (countdown.equals("")) {
                // Fallback: just show current time
                var clockTime = System.getClockTime();
                countdown = Lang.format("$1$:$2$", [
                    clockTime.hour.format("%02d"),
                    clockTime.min.format("%02d")
                ]);
            }
            _timeComponent.setText(countdown);
            _timeComponent.setTextColor(Graphics.COLOR_YELLOW);
        }

        if (_statusComponent != null) {
            var statusText = WatchUi.loadResource(Rez.Strings.ShabbatCountdown) as Lang.String;
            if (_shabbatService != null && !_shabbatService.hasLocation()) {
                statusText = WatchUi.loadResource(Rez.Strings.LocationNeeded) as Lang.String;
            }
            _statusComponent.setText(statusText);
            _statusComponent.setTextColor(Graphics.COLOR_LT_GRAY);
        }
    }

    // -------------------------------------------------------------------------
    // Overlay screens
    // -------------------------------------------------------------------------

    private function drawFirstRunMessage(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        try {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.fillRectangle(0, height * 3 / 4, width, height / 4);

            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                width / 2,
                height * 7 / 8,
                Graphics.FONT_SMALL,
                WatchUi.loadResource(Rez.Strings.FirstRunMessage) as Lang.String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } catch (ex instanceof Lang.Exception) {
            // Ignore errors in first-run overlay
        }
    }

    private function drawErrorScreen(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        try {
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_DK_RED);
            dc.clear();

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                width / 2,
                height / 2 - 20,
                Graphics.FONT_MEDIUM,
                WatchUi.loadResource(Rez.Strings.ShabbatModeTitle) as Lang.String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                width / 2,
                height / 2 + 20,
                Graphics.FONT_SMALL,
                WatchUi.loadResource(Rez.Strings.InitializationError) as Lang.String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );

            dc.drawText(
                width / 2,
                height / 2 + 40,
                Graphics.FONT_TINY,
                WatchUi.loadResource(Rez.Strings.RestartRequired) as Lang.String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );

        } catch (ex instanceof Lang.Exception) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
        }
    }

    // -------------------------------------------------------------------------
    // Public helpers
    // -------------------------------------------------------------------------

    function handleFirstRunComplete() as Void {
        if (_configService != null) {
            _configService.setFirstRunComplete();
            if (_logger != null) {
                _logger.info("First run completed");
            }
        }
    }

    function setStatus(status as Lang.String) as Void {
        if (_statusComponent != null) {
            _statusComponent.setText(status);
            WatchUi.requestUpdate();
        }
    }

    function setStatusColor(color as Lang.Number) as Void {
        if (_statusComponent != null) {
            _statusComponent.setTextColor(color);
            WatchUi.requestUpdate();
        }
    }

    function isInitialized() as Lang.Boolean {
        return _initialized;
    }

    function getConfigService() as ConfigService? {
        return _configService;
    }

    function getComponentCount() as Lang.Number {
        return _components.size();
    }
}

// Input delegate for MainView
class MainViewDelegate extends WatchUi.BehaviorDelegate {

    private var _view as MainView;
    private var _logger as Logger?;

    function initialize(view as MainView) {
        BehaviorDelegate.initialize();
        _view = view;
        _logger = new Logger();
    }

    function onSelect() as Lang.Boolean {
        try {
            if (_view != null) {
                var configService = _view.getConfigService();
                if (configService != null && configService.isFirstRun()) {
                    _view.handleFirstRunComplete();
                    WatchUi.requestUpdate();
                    return true;
                }
            }
            return true;

        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.error("Error in MainViewDelegate onSelect: " + ex.getErrorMessage());
            }
            return false;
        }
    }

    function onBack() as Lang.Boolean {
        return false;
    }

    function onMenu() as Lang.Boolean {
        try {
            if (_logger != null) {
                _logger.debug("Menu button pressed - settings not implemented yet");
            }
            return true;

        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.error("Error in MainViewDelegate onMenu: " + ex.getErrorMessage());
            }
            return false;
        }
    }
}
