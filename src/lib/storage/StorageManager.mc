using Toybox.Application;
using Toybox.Lang;

class StorageManager {

    private var _initialized as Boolean;
    private var _storageKeys as Dictionary<String, Object>;

    // Storage key constants
    static const USER_SETTINGS = "user_settings";
    static const APP_STATE = "app_state";
    static const LAST_LOCATION = "last_location";
    static const TIME_PREFERENCES = "time_preferences";

    function initialize() {
        _initialized = false;
        _storageKeys = {} as Dictionary<String, Object>;

        try {
            // Initialize default storage structure if needed
            if (getValue(USER_SETTINGS) == null) {
                setValue(USER_SETTINGS, getDefaultSettings());
            }

            _initialized = true;

        } catch (ex instanceof Exception) {
            // Handle storage initialization errors
            _initialized = false;
        }
    }

    function isInitialized() as Boolean {
        return _initialized;
    }

    // Generic storage operations
    function setValue(key as String, value as Object?) as Boolean {
        try {
            Application.Storage.setValue(key, value);
            _storageKeys.put(key, true);
            return true;
        } catch (ex instanceof Exception) {
            return false;
        }
    }

    function getValue(key as String) as Object? {
        try {
            return Application.Storage.getValue(key);
        } catch (ex instanceof Exception) {
            return null;
        }
    }

    function deleteValue(key as String) as Boolean {
        try {
            Application.Storage.deleteValue(key);
            _storageKeys.remove(key);
            return true;
        } catch (ex instanceof Exception) {
            return false;
        }
    }

    function clearAll() as Boolean {
        try {
            Application.Storage.clearValues();
            _storageKeys = {} as Dictionary<String, Object>;
            return true;
        } catch (ex instanceof Exception) {
            return false;
        }
    }

    // Specialized storage methods
    function saveUserSettings(settings as Dictionary<String, Object>) as Boolean {
        return setValue(USER_SETTINGS, settings);
    }

    function getUserSettings() as Dictionary<String, Object>? {
        var settings = getValue(USER_SETTINGS);
        if (settings instanceof Dictionary) {
            return settings as Dictionary<String, Object>;
        }
        return getDefaultSettings();
    }

    function saveAppState(state as Dictionary<String, Object>) as Boolean {
        return setValue(APP_STATE, state);
    }

    function getAppState() as Dictionary<String, Object>? {
        var state = getValue(APP_STATE);
        if (state instanceof Dictionary) {
            return state as Dictionary<String, Object>;
        }
        return null;
    }

    function saveLastLocation(location as Dictionary<String, Object>) as Boolean {
        return setValue(LAST_LOCATION, location);
    }

    function getLastLocation() as Dictionary<String, Object>? {
        var location = getValue(LAST_LOCATION);
        if (location instanceof Dictionary) {
            return location as Dictionary<String, Object>;
        }
        return null;
    }

    // Default configurations
    private function getDefaultSettings() as Dictionary<String, Object> {
        return {
            "theme" => "dark",
            "language" => "english",
            "units" => "metric",
            "notifications" => true,
            "auto_save" => true
        } as Dictionary<String, Object>;
    }
}