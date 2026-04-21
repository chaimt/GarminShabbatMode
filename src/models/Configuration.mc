using Toybox.Lang;

class Configuration {

    private var _settings as Lang.Dictionary<Lang.String, Lang.Object>;
    private var _isLoaded as Lang.Boolean;
    private var _isDirty as Lang.Boolean;

    function initialize() {
        _settings = {} as Lang.Dictionary<Lang.String, Lang.Object>;
        _isLoaded = false;
        _isDirty = false;
        loadDefaults();
    }

    function loadDefaults() as Void {
        _settings = {
            // Application settings
            "app_name" => "ShabbatMode",
            "version" => "1.0.0",
            "first_run" => true,

            // Display settings
            "theme" => "dark",
            "brightness" => "auto",
            "font_size" => "medium",
            "show_seconds" => true,

            // Locale settings
            "language" => "english",
            "units" => "metric",
            "time_format" => "24hour",
            "date_format" => "dd/mm/yyyy",

            // Notification settings
            "notifications_enabled" => true,
            "vibration_enabled" => true,
            "sound_enabled" => false,

            // Shabbat-specific settings (placeholders for future features)
            "candle_lighting_offset" => 18,  // minutes before sunset
            "shabbat_end_offset" => 25,      // minutes after sunset
            "location_auto" => true,
            "latitude" => 0.0,
            "longitude" => 0.0,

            // Performance settings
            "auto_save" => true,
            "background_updates" => true,
            "low_power_mode" => false
        } as Lang.Dictionary<Lang.String, Lang.Object>;

        _isLoaded = true;
        _isDirty = true; // Mark as dirty to ensure first save
    }

    // Generic settings methods
    function get(key as Lang.String) as Lang.Object? {
        if (!_isLoaded) {
            loadDefaults();
        }

        if (_settings.hasKey(key)) {
            return _settings.get(key);
        }
        return null;
    }

    function set(key as Lang.String, value as Lang.Object) as Lang.Boolean {
        if (!_isLoaded) {
            loadDefaults();
        }

        try {
            _settings.put(key, value);
            _isDirty = true;
            return true;
        } catch (ex instanceof Lang.Exception) {
            return false;
        }
    }

    function containsKey(key as Lang.String) as Lang.Boolean {
        return _settings.hasKey(key);
    }

    function remove(key as Lang.String) as Lang.Boolean {
        if (_settings.hasKey(key)) {
            _settings.remove(key);
            _isDirty = true;
            return true;
        }
        return false;
    }

    // Typed getter methods
    function getString(key as Lang.String, defaultValue as Lang.String) as Lang.String {
        var value = get(key);
        if (value instanceof String) {
            return value as Lang.String;
        }
        return defaultValue;
    }

    function getNumber(key as Lang.String, defaultValue as Lang.Number) as Lang.Number {
        var value = get(key);
        if (value instanceof Number) {
            return value as Lang.Number;
        }
        return defaultValue;
    }

    function getBoolean(key as Lang.String, defaultValue as Lang.Boolean) as Lang.Boolean {
        var value = get(key);
        if (value instanceof Boolean) {
            return value as Lang.Boolean;
        }
        return defaultValue;
    }

    function getFloat(key as Lang.String, defaultValue as Lang.Float) as Lang.Float {
        var value = get(key);
        if (value instanceof Lang.Float) {
            return value as Lang.Float;
        }
        if (value instanceof Number) {
            return (value as Lang.Number).toFloat();
        }
        return defaultValue;
    }

    // Specific configuration getters
    function getAppName() as Lang.String {
        return getString("app_name", "ShabbatMode");
    }

    function getVersion() as Lang.String {
        return getString("version", "1.0.0");
    }

    function isFirstRun() as Lang.Boolean {
        return getBoolean("first_run", true);
    }

    function setFirstRunComplete() as Void {
        set("first_run", false);
    }

    function getTheme() as Lang.String {
        return getString("theme", "dark");
    }

    function setTheme(theme as Lang.String) as Void {
        set("theme", theme);
    }

    function getLanguage() as Lang.String {
        return getString("language", "english");
    }

    function setLanguage(language as Lang.String) as Void {
        set("language", language);
    }

    function areNotificationsEnabled() as Lang.Boolean {
        return getBoolean("notifications_enabled", true);
    }

    function setNotificationsEnabled(enabled as Lang.Boolean) as Void {
        set("notifications_enabled", enabled);
    }

    function isVibrationEnabled() as Lang.Boolean {
        return getBoolean("vibration_enabled", true);
    }

    function setVibrationEnabled(enabled as Lang.Boolean) as Void {
        set("vibration_enabled", enabled);
    }

    // Shabbat-specific settings
    function getCandleLightingOffset() as Lang.Number {
        return getNumber("candle_lighting_offset", 18);
    }

    function setCandleLightingOffset(minutes as Lang.Number) as Void {
        set("candle_lighting_offset", minutes);
    }

    function getShabbatEndOffset() as Lang.Number {
        return getNumber("shabbat_end_offset", 25);
    }

    function setShabbatEndOffset(minutes as Lang.Number) as Void {
        set("shabbat_end_offset", minutes);
    }

    function isLocationAuto() as Lang.Boolean {
        return getBoolean("location_auto", true);
    }

    function setLocationAuto(auto as Lang.Boolean) as Void {
        set("location_auto", auto);
    }

    function getLatitude() as Lang.Float {
        return getFloat("latitude", 0.0);
    }

    function getLongitude() as Lang.Float {
        return getFloat("longitude", 0.0);
    }

    function setLocation(latitude as Lang.Float, longitude as Lang.Float) as Void {
        set("latitude", latitude);
        set("longitude", longitude);
    }

    // State management
    function isLoaded() as Lang.Boolean {
        return _isLoaded;
    }

    function isDirty() as Lang.Boolean {
        return _isDirty;
    }

    function markClean() as Void {
        _isDirty = false;
    }

    function markDirty() as Void {
        _isDirty = true;
    }

    // Export/import for storage
    function toDict() as Lang.Dictionary<Lang.String, Lang.Object> {
        if (!_isLoaded) {
            loadDefaults();
        }
        return _settings;
    }

    function fromDict(settings as Lang.Dictionary<Lang.String, Lang.Object>) as Lang.Boolean {
        try {
            _settings = settings;
            _isLoaded = true;
            _isDirty = false;
            return true;
        } catch (ex instanceof Lang.Exception) {
            loadDefaults();
            return false;
        }
    }

    // Reset methods
    function reset() as Void {
        loadDefaults();
    }

    function resetToDefaults(key as Lang.String) as Lang.Boolean {
        // This would reset a specific setting to its default value
        // For now, just remove it so default will be used
        return remove(key);
    }
}