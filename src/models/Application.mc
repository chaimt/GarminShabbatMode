using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi;

class ShabbatModeApp extends Application.AppBase {

    private var _appState as Lang.Symbol;
    private var _initialized as Lang.Boolean;
    private var _errorHandler as ErrorHandler?;
    private var _configService as ConfigService?;
    private var _logger as Logger?;
    private var _storageManager as StorageManager?;
    private var _initializationStep as Lang.Number;

    function initialize() {
        AppBase.initialize();
        _appState = :starting;
        _initialized = false;
        _errorHandler = null;
        _configService = null;
        _logger = null;
        _storageManager = null;
        _initializationStep = 0;
    }

    // onStart() is called on application start up
    function onStart(state as Lang.Dictionary?) as Void {
        try {
            _appState = :starting;
            _initializationStep = 1;

            // Step 1: Initialize error handler first
            _errorHandler = new ErrorHandler();
            _initializationStep = 2;

            // Step 2: Initialize logger
            _logger = new Logger();
            _logger.info("ShabbatMode application starting");
            _initializationStep = 3;

            // Step 3: Initialize storage manager
            _storageManager = new StorageManager();
            if (!_storageManager.isInitialized()) {
                throw new Lang.Exception("Storage manager initialization failed");
            }
            _logger.info("Storage manager initialized");
            _initializationStep = 4;

            // Step 4: Initialize configuration service
            _configService = new ConfigService();
            if (!_configService.initializeService()) {
                throw new Lang.Exception("Configuration service initialization failed");
            }
            _logger.info("Configuration service initialized");
            _initializationStep = 5;

            // Step 5: Check if this is first run
            if (_configService.isFirstRun()) {
                _logger.info("First run detected, showing welcome experience");
            }

            // Step 6: Set application as fully initialized.
            // Screen refresh is driven by the 1-second Timer started in MainView.onShow()
            // so no TimeService.start() call is required here.
            _initialized = true;
            _appState = :running;
            _initializationStep = 6;

            _logger.info("Application started successfully");

        } catch (ex instanceof Lang.Exception) {
            var errorMessage = "Application start failed at step " + _initializationStep;

            if (_logger != null) {
                _logger.error(errorMessage + ": " + ex.getErrorMessage());
            } else {
                System.println(errorMessage + ": " + ex.getErrorMessage());
            }

            if (_errorHandler != null) {
                _errorHandler.handleError("Application startup", ex);
            }

            _appState = :error;
            _initialized = false;
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state as Lang.Dictionary?) as Void {
        try {
            _appState = :stopping;

            if (_logger != null) {
                _logger.info("Application stopping");
            }

            // Save configuration before shutdown if dirty
            if (_configService != null) {
                try {
                    _configService.forceSave();
                    if (_logger != null) {
                        _logger.debug("Configuration saved on shutdown");
                    }
                } catch (configEx instanceof Lang.Exception) {
                    if (_logger != null) {
                        _logger.warn("Failed to save configuration on shutdown: " + configEx.getErrorMessage());
                    }
                }
            }

            // Clean up resources
            _initialized = false;
            _appState = :stopped;
            _initializationStep = 0;

            if (_logger != null) {
                _logger.info("Application stopped successfully");
            }

        } catch (ex instanceof Lang.Exception) {
            // Minimal error handling during shutdown
            _appState = :error;
            System.println("Error during application shutdown: " + ex.getErrorMessage());
        }
    }

    // Return the initial view of your application here
    function getInitialView() as Lang.Array? {
        try {
            var mainView = new MainView();
            var mainViewDelegate = new MainViewDelegate(mainView);

            return [ mainView, mainViewDelegate ];

        } catch (ex instanceof Lang.Exception) {
            if (_logger != null) {
                _logger.error("Failed to create initial view: " + ex.getErrorMessage());
            }

            // Return a simple error view if main view fails
            return null;
        }
    }

    // onSettingsChanged() is called when the user changes settings
    function onSettingsChanged() as Void {
        try {
            if (_logger != null) {
                _logger.info("Settings changed, requesting update");
            }

            // Force configuration reload and save
            if (_configService != null) {
                _configService.loadConfiguration();
            }

            // Request UI update
            WatchUi.requestUpdate();

        } catch (ex instanceof Lang.Exception) {
            if (_errorHandler != null) {
                _errorHandler.handleError("Settings change", ex);
            }
        }
    }

    // Application state management
    function getState() as Lang.Symbol {
        return _appState;
    }

    function isInitialized() as Lang.Boolean {
        return _initialized;
    }

    function getInitializationStep() as Lang.Number {
        return _initializationStep;
    }

    function getErrorHandler() as ErrorHandler? {
        return _errorHandler;
    }

    function getConfigService() as ConfigService? {
        return _configService;
    }

    function getLogger() as Logger? {
        return _logger;
    }

    function getStorageManager() as StorageManager? {
        return _storageManager;
    }

    // Restart application
    function restart() as Void {
        try {
            if (_logger != null) {
                _logger.info("Application restart requested");
            }

            // Reset state
            _initialized = false;
            _appState = :restarting;

            // Reinitialize
            onStart(null);

        } catch (ex instanceof Lang.Exception) {
            if (_errorHandler != null) {
                _errorHandler.handleError("Application restart", ex);
            }
        }
    }

    // Handle low memory warning
    function onMemoryWarning() as Void {
        try {
            if (_logger != null) {
                _logger.warn("Low memory warning received");
            }

            // Force save configuration to preserve data
            if (_configService != null) {
                _configService.forceSave();
            }

            // Could implement additional memory cleanup here

        } catch (ex instanceof Lang.Exception) {
            if (_errorHandler != null) {
                _errorHandler.handleError("Memory warning", ex);
            }
        }
    }
}