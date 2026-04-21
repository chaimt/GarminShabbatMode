using Toybox.Lang;

class TimeConfiguration {

    private var _settings as Dictionary<String, Object>;
    private var _isLoaded as Boolean;
    private var _isDirty as Boolean;

    function initialize() {
        _settings = {} as Dictionary<String, Object>;
        _isLoaded = false;
        _isDirty = false;
        loadDefaults();
    }

    function loadDefaults() as Void {
        _settings = {
            // Time display preferences
            "time_format" => 24,              // 12 or 24 hour format
            "show_seconds" => true,           // Show seconds in time display
            "show_date" => true,              // Show date along with time
            "date_format" => "dd/mm/yyyy",    // Date format string
            "auto_update_interval" => 1,     // Update interval in seconds

            // Shabbat time calculation settings
            "candle_lighting_offset" => 18,  // Minutes before sunset
            "shabbat_end_offset" => 25,      // Minutes after sunset (Rabbenu Tam: 72)
            "use_rabbenu_tam" => false,      // Use Rabbenu Tam's 72-minute opinion
            "shabbat_end_custom" => 25,      // Custom end offset if not using Rabbenu Tam

            // Location and timezone settings
            "auto_location" => true,         // Use GPS for location
            "manual_latitude" => 0.0,        // Manual latitude if auto_location is false
            "manual_longitude" => 0.0,       // Manual longitude if auto_location is false
            "timezone_auto" => true,         // Auto-detect timezone
            "timezone_manual" => "UTC",      // Manual timezone if auto is false
            "location_update_interval" => 300, // Location update interval in seconds (5 min)

            // Calculation preferences
            "calculation_method" => "standard", // "standard", "accurate", "fast"
            "elevation_correction" => true,   // Account for elevation in calculations
            "atmospheric_refraction" => true, // Account for atmospheric refraction
            "precision_minutes" => 1,        // Rounding precision in minutes

            // Cache and performance settings
            "cache_calculations" => true,    // Cache daily calculations
            "cache_duration_hours" => 24,    // How long to cache calculations
            "background_updates" => true,    // Update calculations in background
            "low_power_mode" => false,       // Reduce calculation frequency

            // Regional customs and variations
            "region" => "standard",          // "israel", "diaspora", "custom"
            "custom_candle_offset" => 18,    // Custom candle lighting offset
            "custom_end_offset" => 25,       // Custom shabbat end offset
            "stringency_level" => "moderate", // "strict", "moderate", "lenient"

            // Holiday and special Shabbat settings
            "handle_festivals" => true,      // Adjust for Jewish festivals
            "erev_yom_tov_offset" => 18,    // Candle lighting for festivals
            "motzash_offset" => 25,         // Saturday night offset
            "early_shabbat_allowed" => true, // Allow early Shabbat acceptance

            // Display and notification settings
            "show_countdown" => true,        // Show countdown to Shabbat start/end
            "notification_enabled" => true,  // Enable time-based notifications
            "notification_minutes_before" => 10, // Notify X minutes before times
            "vibration_enabled" => true,    // Vibration for notifications
            "sound_enabled" => false        // Sound for notifications (usually off for Shabbat)
        } as Dictionary<String, Object>;

        _isLoaded = true;
        _isDirty = true;
    }

    // Generic settings access
    function get(key as String) as Object? {
        if (!_isLoaded) {
            loadDefaults();
        }

        if (_settings.hasKey(key)) {
            return _settings.get(key);
        }
        return null;
    }

    function set(key as String, value as Object) as Boolean {
        if (!_isLoaded) {
            loadDefaults();
        }

        try {
            _settings.put(key, value);
            _isDirty = true;
            return true;
        } catch (ex instanceof Exception) {
            return false;
        }
    }

    function has(key as String) as Boolean {
        return _settings.hasKey(key);
    }

    // Typed getters with validation
    function getNumber(key as String, defaultValue as Number) as Number {
        var value = get(key);
        if (value instanceof Number) {
            return value as Number;
        }
        return defaultValue;
    }

    function getFloat(key as String, defaultValue as Float) as Float {
        var value = get(key);
        if (value instanceof Float) {
            return value as Float;
        }
        if (value instanceof Number) {
            return (value as Number).toFloat();
        }
        return defaultValue;
    }

    function getBoolean(key as String, defaultValue as Boolean) as Boolean {
        var value = get(key);
        if (value instanceof Boolean) {
            return value as Boolean;
        }
        return defaultValue;
    }

    function getString(key as String, defaultValue as String) as String {
        var value = get(key);
        if (value instanceof String) {
            return value as String;
        }
        return defaultValue;
    }

    // Time format settings
    function getTimeFormat() as Number {
        return getNumber("time_format", 24);
    }

    function setTimeFormat(format as Number) as Boolean {
        if (format == 12 || format == 24) {
            return set("time_format", format);
        }
        return false;
    }

    function shouldShowSeconds() as Boolean {
        return getBoolean("show_seconds", true);
    }

    function setShowSeconds(show as Boolean) as Boolean {
        return set("show_seconds", show);
    }

    function shouldShowDate() as Boolean {
        return getBoolean("show_date", true);
    }

    function setShowDate(show as Boolean) as Boolean {
        return set("show_date", show);
    }

    function getDateFormat() as String {
        return getString("date_format", "dd/mm/yyyy");
    }

    function setDateFormat(format as String) as Boolean {
        // Basic validation of date format
        if (format.length() > 0) {
            return set("date_format", format);
        }
        return false;
    }

    function getAutoUpdateInterval() as Number {
        return getNumber("auto_update_interval", 1);
    }

    function setAutoUpdateInterval(interval as Number) as Boolean {
        if (interval > 0 && interval <= 60) {
            return set("auto_update_interval", interval);
        }
        return false;
    }

    // Shabbat calculation settings
    function getCandleLightingOffset() as Number {
        return getNumber("candle_lighting_offset", 18);
    }

    function setCandleLightingOffset(offset as Number) as Boolean {
        if (offset >= 0 && offset <= 60) {
            return set("candle_lighting_offset", offset);
        }
        return false;
    }

    function getShabbatEndOffset() as Number {
        if (useRabbenuTam()) {
            return 72; // Fixed for Rabbenu Tam
        }
        return getNumber("shabbat_end_offset", 25);
    }

    function setShabbatEndOffset(offset as Number) as Boolean {
        if (offset >= 0 && offset <= 120) {
            return set("shabbat_end_offset", offset);
        }
        return false;
    }

    function useRabbenuTam() as Boolean {
        return getBoolean("use_rabbenu_tam", false);
    }

    function setUseRabbenuTam(use as Boolean) as Boolean {
        return set("use_rabbenu_tam", use);
    }

    // Location settings
    function isAutoLocationEnabled() as Boolean {
        return getBoolean("auto_location", true);
    }

    function setAutoLocationEnabled(enabled as Boolean) as Boolean {
        return set("auto_location", enabled);
    }

    function getManualLatitude() as Float {
        return getFloat("manual_latitude", 0.0);
    }

    function getManualLongitude() as Float {
        return getFloat("manual_longitude", 0.0);
    }

    function setManualLocation(latitude as Float, longitude as Float) as Boolean {
        // Validate coordinates
        if (latitude >= -90.0 && latitude <= 90.0 &&
            longitude >= -180.0 && longitude <= 180.0) {

            var success1 = set("manual_latitude", latitude);
            var success2 = set("manual_longitude", longitude);
            return success1 && success2;
        }
        return false;
    }

    function isTimezoneAuto() as Boolean {
        return getBoolean("timezone_auto", true);
    }

    function setTimezoneAuto(auto as Boolean) as Boolean {
        return set("timezone_auto", auto);
    }

    function getManualTimezone() as String {
        return getString("timezone_manual", "UTC");
    }

    function setManualTimezone(timezone as String) as Boolean {
        if (timezone.length() > 0) {
            return set("timezone_manual", timezone);
        }
        return false;
    }

    function getLocationUpdateInterval() as Number {
        return getNumber("location_update_interval", 300);
    }

    function setLocationUpdateInterval(interval as Number) as Boolean {
        if (interval >= 30 && interval <= 3600) { // 30 seconds to 1 hour
            return set("location_update_interval", interval);
        }
        return false;
    }

    // Calculation preferences
    function getCalculationMethod() as String {
        return getString("calculation_method", "standard");
    }

    function setCalculationMethod(method as String) as Boolean {
        if (method.equals("standard") || method.equals("accurate") || method.equals("fast")) {
            return set("calculation_method", method);
        }
        return false;
    }

    function shouldUseElevationCorrection() as Boolean {
        return getBoolean("elevation_correction", true);
    }

    function setUseElevationCorrection(use as Boolean) as Boolean {
        return set("elevation_correction", use);
    }

    function shouldUseAtmosphericRefraction() as Boolean {
        return getBoolean("atmospheric_refraction", true);
    }

    function setUseAtmosphericRefraction(use as Boolean) as Boolean {
        return set("atmospheric_refraction", use);
    }

    function getPrecisionMinutes() as Number {
        return getNumber("precision_minutes", 1);
    }

    function setPrecisionMinutes(precision as Number) as Boolean {
        if (precision >= 1 && precision <= 10) {
            return set("precision_minutes", precision);
        }
        return false;
    }

    // Cache and performance settings
    function shouldCacheCalculations() as Boolean {
        return getBoolean("cache_calculations", true);
    }

    function setCacheCalculations(cache as Boolean) as Boolean {
        return set("cache_calculations", cache);
    }

    function getCacheDurationHours() as Number {
        return getNumber("cache_duration_hours", 24);
    }

    function setCacheDurationHours(hours as Number) as Boolean {
        if (hours >= 1 && hours <= 168) { // 1 hour to 1 week
            return set("cache_duration_hours", hours);
        }
        return false;
    }

    function shouldAllowBackgroundUpdates() as Boolean {
        return getBoolean("background_updates", true);
    }

    function setAllowBackgroundUpdates(allow as Boolean) as Boolean {
        return set("background_updates", allow);
    }

    function isLowPowerMode() as Boolean {
        return getBoolean("low_power_mode", false);
    }

    function setLowPowerMode(lowPower as Boolean) as Boolean {
        return set("low_power_mode", lowPower);
    }

    // Regional and custom settings
    function getRegion() as String {
        return getString("region", "standard");
    }

    function setRegion(region as String) as Boolean {
        if (region.equals("israel") || region.equals("diaspora") ||
            region.equals("custom") || region.equals("standard")) {
            return set("region", region);
        }
        return false;
    }

    function getStringencyLevel() as String {
        return getString("stringency_level", "moderate");
    }

    function setStringencyLevel(level as String) as Boolean {
        if (level.equals("strict") || level.equals("moderate") || level.equals("lenient")) {
            return set("stringency_level", level);
        }
        return false;
    }

    // Notification settings
    function areNotificationsEnabled() as Boolean {
        return getBoolean("notification_enabled", true);
    }

    function setNotificationsEnabled(enabled as Boolean) as Boolean {
        return set("notification_enabled", enabled);
    }

    function getNotificationMinutesBefore() as Number {
        return getNumber("notification_minutes_before", 10);
    }

    function setNotificationMinutesBefore(minutes as Number) as Boolean {
        if (minutes >= 0 && minutes <= 60) {
            return set("notification_minutes_before", minutes);
        }
        return false;
    }

    function isVibrationEnabled() as Boolean {
        return getBoolean("vibration_enabled", true);
    }

    function setVibrationEnabled(enabled as Boolean) as Boolean {
        return set("vibration_enabled", enabled);
    }

    function isSoundEnabled() as Boolean {
        return getBoolean("sound_enabled", false);
    }

    function setSoundEnabled(enabled as Boolean) as Boolean {
        return set("sound_enabled", enabled);
    }

    // State management
    function isLoaded() as Boolean {
        return _isLoaded;
    }

    function isDirty() as Boolean {
        return _isDirty;
    }

    function markClean() as Void {
        _isDirty = false;
    }

    function markDirty() as Void {
        _isDirty = true;
    }

    // Export/import for storage
    function toDict() as Dictionary<String, Object> {
        if (!_isLoaded) {
            loadDefaults();
        }
        return _settings;
    }

    function fromDict(settings as Dictionary<String, Object>) as Boolean {
        try {
            _settings = settings;
            _isLoaded = true;
            _isDirty = false;
            return true;
        } catch (ex instanceof Exception) {
            loadDefaults();
            return false;
        }
    }

    // Reset methods
    function reset() as Void {
        loadDefaults();
    }

    function resetSetting(key as String) as Boolean {
        if (_settings.hasKey(key)) {
            _settings.remove(key);
            _isDirty = true;

            // Reload defaults to get the default value back
            var tempSettings = _settings;
            loadDefaults();

            // Restore non-default settings
            var defaultValue = _settings.get(key);
            _settings = tempSettings;
            if (defaultValue != null) {
                _settings.put(key, defaultValue);
            }

            return true;
        }
        return false;
    }
}