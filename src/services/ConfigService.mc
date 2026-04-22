using Toybox.Lang;

class ConfigService {

    private var _configuration as Configuration;
    private var _storageManager as StorageManager;
    private var _logger as Logger;
    private var _isInitialized as Lang.Boolean;

    function initialize() {
        _configuration = new Configuration();
        _storageManager = new StorageManager();
        _logger = new Logger();
        _isInitialized = false;
    }

    function initializeService() as Lang.Boolean {
        try {
            // Initialize storage manager first
            _storageManager.initialize();

            // Load existing configuration from storage
            var success = loadConfiguration();

            if (success) {
                _logger.info("ConfigService initialized successfully");
                _isInitialized = true;
                return true;
            } else {
                _logger.warn("ConfigService initialized with defaults (no saved config found)");
                _isInitialized = true;
                return true; // Still successful, just using defaults
            }

        } catch (ex instanceof Lang.Exception) {
            _logger.error("Failed to initialize ConfigService: " + ex.getErrorMessage());
            _isInitialized = false;
            return false;
        }
    }

    function isInitialized() as Lang.Boolean {
        return _isInitialized;
    }

    // Configuration loading and saving
    function loadConfiguration() as Lang.Boolean {
        try {
            var savedSettings = _storageManager.getUserSettings();

            if (savedSettings != null) {
                var success = _configuration.fromDict(savedSettings);
                if (success) {
                    _logger.debug("Configuration loaded from storage");
                    return true;
                } else {
                    _logger.warn("Failed to parse saved configuration, using defaults");
                    return false;
                }
            } else {
                _logger.debug("No saved configuration found, using defaults");
                return false;
            }

        } catch (ex instanceof Lang.Exception) {
            _logger.error("Error loading configuration: " + ex.getErrorMessage());
            return false;
        }
    }

    function saveConfiguration() as Lang.Boolean {
        if (!_isInitialized) {
            _logger.error("ConfigService not initialized, cannot save");
            return false;
        }

        try {
            if (_configuration.isDirty()) {
                var settings = _configuration.toDict();
                var success = _storageManager.saveUserSettings(settings);

                if (success) {
                    _configuration.markClean();
                    _logger.debug("Configuration saved successfully");
                    return true;
                } else {
                    _logger.error("Failed to save configuration to storage");
                    return false;
                }
            } else {
                _logger.debug("Configuration not dirty, skipping save");
                return true; // Not dirty, so "successful" save
            }

        } catch (ex instanceof Lang.Exception) {
            _logger.error("Error saving configuration: " + ex.getErrorMessage());
            return false;
        }
    }

    function autoSave() as Lang.Boolean {
        if (_configuration.getBoolean("auto_save", true)) {
            return saveConfiguration();
        }
        return true; // Auto-save disabled, so "successful"
    }

    // Generic configuration access
    function get(key as Lang.String) as Lang.Object? {
        if (!_isInitialized) {
            return null;
        }
        return _configuration.get(key);
    }

    function set(key as Lang.String, value as Lang.Object) as Lang.Boolean {
        if (!_isInitialized) {
            return false;
        }

        var success = _configuration.set(key, value);
        if (success) {
            autoSave();
        }
        return success;
    }

    function containsKey(key as Lang.String) as Lang.Boolean {
        if (!_isInitialized) {
            return false;
        }
        return _configuration.containsKey(key);
    }

    function remove(key as Lang.String) as Lang.Boolean {
        if (!_isInitialized) {
            return false;
        }

        var success = _configuration.remove(key);
        if (success) {
            autoSave();
        }
        return success;
    }

    // Typed getters with validation
    function getString(key as Lang.String, defaultValue as Lang.String) as Lang.String {
        if (!_isInitialized) {
            return defaultValue;
        }
        return _configuration.getString(key, defaultValue);
    }

    function getNumber(key as Lang.String, defaultValue as Lang.Number) as Lang.Number {
        if (!_isInitialized) {
            return defaultValue;
        }
        return _configuration.getNumber(key, defaultValue);
    }

    function getBoolean(key as Lang.String, defaultValue as Lang.Boolean) as Lang.Boolean {
        if (!_isInitialized) {
            return defaultValue;
        }
        return _configuration.getBoolean(key, defaultValue);
    }

    function getFloat(key as Lang.String, defaultValue as Lang.Float) as Lang.Float {
        if (!_isInitialized) {
            return defaultValue;
        }
        return _configuration.getFloat(key, defaultValue);
    }

    // Application-specific configuration methods
    function getAppName() as Lang.String {
        return _configuration.getAppName();
    }

    function getVersion() as Lang.String {
        return _configuration.getVersion();
    }

    function isFirstRun() as Lang.Boolean {
        return _configuration.isFirstRun();
    }

    function setFirstRunComplete() as Lang.Boolean {
        _configuration.setFirstRunComplete();
        return autoSave();
    }

    function getTheme() as Lang.String {
        return _configuration.getTheme();
    }

    function setTheme(theme as Lang.String) as Lang.Boolean {
        // Validate theme
        if (theme.equals("light") || theme.equals("dark") || theme.equals("auto")) {
            _configuration.setTheme(theme);
            return autoSave();
        } else {
            _logger.warn("Invalid theme value: " + theme);
            return false;
        }
    }

    function getLanguage() as Lang.String {
        return _configuration.getLanguage();
    }

    function setLanguage(language as Lang.String) as Lang.Boolean {
        // Basic validation - could be expanded
        if (language.length() > 0) {
            _configuration.setLanguage(language);
            return autoSave();
        } else {
            _logger.warn("Invalid language value: " + language);
            return false;
        }
    }

    function areNotificationsEnabled() as Lang.Boolean {
        return _configuration.areNotificationsEnabled();
    }

    function setNotificationsEnabled(enabled as Lang.Boolean) as Lang.Boolean {
        _configuration.setNotificationsEnabled(enabled);
        return autoSave();
    }

    function isVibrationEnabled() as Lang.Boolean {
        return _configuration.isVibrationEnabled();
    }

    function setVibrationEnabled(enabled as Lang.Boolean) as Lang.Boolean {
        _configuration.setVibrationEnabled(enabled);
        return autoSave();
    }

    // Shabbat-specific configuration
    function getCandleLightingOffset() as Lang.Number {
        return _configuration.getCandleLightingOffset();
    }

    function setCandleLightingOffset(minutes as Lang.Number) as Lang.Boolean {
        // Validate offset (reasonable range)
        if (minutes >= 0 && minutes <= 60) {
            _configuration.setCandleLightingOffset(minutes);
            return autoSave();
        } else {
            _logger.warn("Invalid candle lighting offset: " + minutes);
            return false;
        }
    }

    function getShabbatEndOffset() as Lang.Number {
        return _configuration.getShabbatEndOffset();
    }

    function setShabbatEndOffset(minutes as Lang.Number) as Lang.Boolean {
        // Validate offset (reasonable range)
        if (minutes >= 0 && minutes <= 120) {
            _configuration.setShabbatEndOffset(minutes);
            return autoSave();
        } else {
            _logger.warn("Invalid shabbat end offset: " + minutes);
            return false;
        }
    }

    function isLocationAuto() as Lang.Boolean {
        return _configuration.isLocationAuto();
    }

    function setLocationAuto(auto as Lang.Boolean) as Lang.Boolean {
        _configuration.setLocationAuto(auto);
        return autoSave();
    }

    // Returns "gps" (default) or "manual".
    function getLocationSource() as Lang.String {
        return _configuration.getLocationSource();
    }

    // Accepts "gps" or "manual"; persists immediately.
    function setLocationSource(source as Lang.String) as Lang.Boolean {
        _configuration.setLocationSource(source);
        return autoSave();
    }

    function getLatitude() as Lang.Float {
        return _configuration.getLatitude();
    }

    function getLongitude() as Lang.Float {
        return _configuration.getLongitude();
    }

    function setLocation(latitude as Lang.Float, longitude as Lang.Float) as Lang.Boolean {
        // Validate coordinates
        var validationResult = Validator.validateCoordinates(latitude, longitude);
        if (Validator.isValid(validationResult)) {
            _configuration.setLocation(latitude, longitude);
            return autoSave();
        } else {
            _logger.warn("Invalid coordinates: lat=" + latitude + ", lon=" + longitude);
            return false;
        }
    }

    // Configuration management
    function resetConfiguration() as Lang.Boolean {
        try {
            _configuration.reset();
            _logger.info("Configuration reset to defaults");
            return saveConfiguration();
        } catch (ex instanceof Lang.Exception) {
            _logger.error("Error resetting configuration: " + ex.getErrorMessage());
            return false;
        }
    }

    function resetSetting(key as Lang.String) as Lang.Boolean {
        try {
            var success = _configuration.resetToDefaults(key);
            if (success) {
                _logger.debug("Setting reset to default: " + key);
                return autoSave();
            } else {
                _logger.warn("Failed to reset setting: " + key);
                return false;
            }
        } catch (ex instanceof Lang.Exception) {
            _logger.error("Error resetting setting " + key + ": " + ex.getErrorMessage());
            return false;
        }
    }

    // Export configuration for debugging
    function exportConfiguration() as Lang.Dictionary<Lang.String, Lang.Object>? {
        if (!_isInitialized) {
            return null;
        }
        return _configuration.toDict();
    }

    // Force save (bypass auto-save setting)
    function forceSave() as Lang.Boolean {
        if (!_isInitialized) {
            return false;
        }

        try {
            var settings = _configuration.toDict();
            var success = _storageManager.saveUserSettings(settings);

            if (success) {
                _configuration.markClean();
                _logger.info("Configuration force saved");
                return true;
            } else {
                _logger.error("Failed to force save configuration");
                return false;
            }

        } catch (ex instanceof Lang.Exception) {
            _logger.error("Error force saving configuration: " + ex.getErrorMessage());
            return false;
        }
    }
}