using Toybox.Application;
using Toybox.Lang;

class StorageManager {

    private var _initialized as Lang.Boolean;
    private var _storageKeys as Lang.Dictionary<Lang.String, Lang.Object>;

    // Storage key constants
    static const USER_SETTINGS = "user_settings";
    static const APP_STATE = "app_state";
    static const LAST_LOCATION = "last_location";
    static const TIME_PREFERENCES = "time_preferences";

    function initialize() {
        _initialized = false;
        _storageKeys = {} as Lang.Dictionary<Lang.String, Lang.Object>;

        try {
            // Initialize default storage structure if needed
            if (getValue(USER_SETTINGS) == null) {
                setValue(USER_SETTINGS, getDefaultSettings());
            }

            _initialized = true;

        } catch (ex instanceof Lang.Exception) {
            // Handle storage initialization errors
            _initialized = false;
        }
    }

    function isInitialized() as Lang.Boolean {
        return _initialized;
    }

    // Generic storage operations
    function setValue(key as Lang.String, value as Lang.Object?) as Lang.Boolean {
        try {
            Application.Storage.setValue(key, value);
            _storageKeys.put(key, true);
            return true;
        } catch (ex instanceof Lang.Exception) {
            return false;
        }
    }

    function getValue(key as Lang.String) as Lang.Object? {
        try {
            return Application.Storage.getValue(key);
        } catch (ex instanceof Lang.Exception) {
            return null;
        }
    }

    function deleteValue(key as Lang.String) as Lang.Boolean {
        try {
            Application.Storage.deleteValue(key);
            _storageKeys.remove(key);
            return true;
        } catch (ex instanceof Lang.Exception) {
            return false;
        }
    }

    function clearAll() as Lang.Boolean {
        try {
            Application.Storage.clearValues();
            _storageKeys = {} as Lang.Dictionary<Lang.String, Lang.Object>;
            return true;
        } catch (ex instanceof Lang.Exception) {
            return false;
        }
    }

    // Specialized storage methods
    function saveUserSettings(settings as Lang.Dictionary<Lang.String, Lang.Object>) as Lang.Boolean {
        return setValue(USER_SETTINGS, settings);
    }

    function getUserSettings() as Lang.Dictionary<Lang.String, Lang.Object>? {
        var settings = getValue(USER_SETTINGS);
        if (settings instanceof Dictionary) {
            return settings as Lang.Dictionary<Lang.String, Lang.Object>;
        }
        return getDefaultSettings();
    }

    function saveAppState(state as Lang.Dictionary<Lang.String, Lang.Object>) as Lang.Boolean {
        return setValue(APP_STATE, state);
    }

    function getAppState() as Lang.Dictionary<Lang.String, Lang.Object>? {
        var state = getValue(APP_STATE);
        if (state instanceof Dictionary) {
            return state as Lang.Dictionary<Lang.String, Lang.Object>;
        }
        return null;
    }

    function saveLastLocation(location as Lang.Dictionary<Lang.String, Lang.Object>) as Lang.Boolean {
        return setValue(LAST_LOCATION, location);
    }

    function getLastLocation() as Lang.Dictionary<Lang.String, Lang.Object>? {
        var location = getValue(LAST_LOCATION);
        if (location instanceof Dictionary) {
            return location as Lang.Dictionary<Lang.String, Lang.Object>;
        }
        return null;
    }

    // Default configurations
    private function getDefaultSettings() as Lang.Dictionary<Lang.String, Lang.Object> {
        return {
            "theme" => "dark",
            "language" => "english",
            "units" => "metric",
            "notifications" => true,
            "auto_save" => true
        } as Lang.Dictionary<Lang.String, Lang.Object>;
    }
}