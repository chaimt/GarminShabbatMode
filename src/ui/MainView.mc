using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Application;

class MainView extends WatchUi.View {

    private var _configService as ConfigService?;
    private var _logger as Logger?;
    private var _components as Lang.Array<BaseComponent>;
    private var _appNameComponent as TextComponent?;
    private var _statusComponent as TextComponent?;
    private var _timeComponent as TextComponent?;
    private var _initialized as Lang.Boolean;

    function initialize() {
        View.initialize();
        _components = [] as Lang.Array<BaseComponent>;
        _initialized = false;

        try {
            // Initialize services
            _configService = new ConfigService();
            _configService.initializeService();

            _logger = new Logger();
            _logger.info("MainView initializing");

            _initialized = true;

        } catch (ex instanceof Lang.Exception) {
            _initialized = false;
            // Fallback error handling if logger isn't available
            System.println("MainView initialization failed: " + ex.getErrorMessage());
        }
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
        if (_logger != null) {
            _logger.debug("MainView onShow");
        }
    }

    // Called when this View is removed from the screen
    function onHide() as Void {
        if (_logger != null) {
            _logger.debug("MainView onHide");
        }
    }

    // Update the view
    function onUpdate(dc as Graphics.Dc) as Void {
        try {
            // Get device dimensions
            var width = dc.getWidth();
            var height = dc.getHeight();

            // Clear the screen
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();

            if (!_initialized) {
                drawErrorScreen(dc, width, height);
                return;
            }

            // Setup components if not already done
            if (_components.size() == 0) {
                setupComponents(width, height);
            }

            // Draw all components
            for (var i = 0; i < _components.size(); i++) {
                _components[i].draw(dc);
            }

            // Update time display
            updateTimeDisplay();

            // Show first run message if this is the first time
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

    private function setupComponents(screenWidth as Lang.Number, screenHeight as Lang.Number) as Void {
        try {
            // Calculate layout dimensions
            var topY = screenHeight / 6;
            var middleY = screenHeight / 2;
            var bottomY = screenHeight * 2 / 3;

            // App name component (top)
            var appName = "ShabbatMode";
            if (_configService != null) {
                appName = _configService.getAppName();
            }

            _appNameComponent = new TextComponent(
                0, topY - 20, screenWidth, 40, appName
            );
            _appNameComponent.setTextColor(Graphics.COLOR_WHITE);
            _appNameComponent.setFont(Graphics.FONT_LARGE);
            _components.add(_appNameComponent);

            // Current time component (center)
            _timeComponent = new TextComponent(
                0, middleY - 20, screenWidth, 40, "00:00:00"
            );
            _timeComponent.setTextColor(Graphics.COLOR_LT_GRAY);
            _timeComponent.setFont(Graphics.FONT_LARGE);
            _components.add(_timeComponent);

            // Status component (bottom)
            var statusText = _initialized ? "Ready" : "Error";
            _statusComponent = new TextComponent(
                0, bottomY - 15, screenWidth, 30, statusText
            );
            _statusComponent.setTextColor(
                _initialized ? Graphics.COLOR_GREEN : Graphics.COLOR_RED
            );
            _statusComponent.setFont(Graphics.FONT_MEDIUM);
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

    private function updateTimeDisplay() as Void {
        if (_timeComponent == null) {
            return;
        }

        try {
            var clockTime = System.getClockTime();
            var timeString = Lang.format("$1$:$2$:$3$", [
                clockTime.hour.format("%02d"),
                clockTime.min.format("%02d"),
                clockTime.sec.format("%02d")
            ]);

            _timeComponent.setText(timeString);

        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.error("Error updating time display: " + ex.getErrorMessage());
            }
            _timeComponent.setText("--:--:--");
        }
    }

    private function drawFirstRunMessage(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        try {
            // Draw semi-transparent overlay
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.fillRectangle(0, height * 3 / 4, width, height / 4);

            // Draw welcome message
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                width / 2,
                height * 7 / 8,
                Graphics.FONT_SMALL,
                "Welcome! Press SELECT to continue",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );

        } catch (ex instanceof Lang.Exception) {
            // Ignore errors in first run message display
        }
    }

    private function drawErrorScreen(dc as Graphics.Dc, width as Lang.Number, height as Lang.Number) as Void {
        try {
            // Clear screen with error background
            dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_DK_RED);
            dc.clear();

            // Draw error message
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                width / 2,
                height / 2 - 20,
                Graphics.FONT_MEDIUM,
                "ShabbatMode",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );

            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                width / 2,
                height / 2 + 20,
                Graphics.FONT_SMALL,
                "Initialization Error",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );

            dc.drawText(
                width / 2,
                height / 2 + 40,
                Graphics.FONT_TINY,
                "Please restart the app",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );

        } catch (ex instanceof Lang.Exception) {
            // If even error screen fails, just clear to black
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
        }
    }

    // Handle first run completion
    function handleFirstRunComplete() as Void {
        if (_configService != null) {
            _configService.setFirstRunComplete();
            if (_logger != null) {
                _logger.info("First run completed");
            }
        }
    }

    // Update status message
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

    // Getters for testing/debugging
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
                    _view.setStatus("Ready");
                    _view.setStatusColor(Graphics.COLOR_GREEN);
                    WatchUi.requestUpdate();
                    return true;
                }
            }

            // For normal operation, this could open a menu or perform other actions
            return true;

        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.error("Error in MainViewDelegate onSelect: " + ex.getErrorMessage());
            }
            return false;
        }
    }

    function onBack() as Lang.Boolean {
        // On the main view, back button might exit the app or do nothing
        // For now, let the system handle it
        return false;
    }

    function onMenu() as Lang.Boolean {
        try {
            // Future: Open settings menu
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