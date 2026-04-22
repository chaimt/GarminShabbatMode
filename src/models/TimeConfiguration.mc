using Toybox.Lang;

class TimeConfiguration {

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
            // Time display preferences
            "time_format" => 24,              // 12 or 24 hour format
            "show_seconds" => true,           // Show seconds in time display
            "show_date" => true,              // Show date along with time
            "date_format" => "dd/mm/yyyy",    // Date format string
            "auto_update_interval" => 1,     // Update interval in seconds

            // Shabbat time calculation settings
            "candle_lighting_offset" => 18,  // Minutes before sunset
            "shabbat_end_offset" => 42,      // Minutes after sunset — Rabbeinu Tam (default)
            "use_rabbenu_tam" => false,      // Use Rabbeinu Tam's strict 72-minute opinion
            "shabbat_end_custom" => 42,      // Custom end offset if not using strict Rabbeinu Tam
            // Tzais calculation method (FR-014):
            //   "fixed_minutes"  — KosherJava ZmanimCalendar.getTzais()  (uses shabbat_end_offset)
            //   "degrees_8_5"    — KosherJava getTzaisGeonim8Point5Degrees()  (zenith 98.5°)
            //   "degrees_7_083"  — KosherJava getTzaisGeonim7Point083Degrees() (zenith 97.083°)
            "tzais_method" => "fixed_minutes",

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
        } as Lang.Dictionary<Lang.String, Lang.Object>;

        _isLoaded = true;
        _isDirty = true;
    }

    // Generic settings access
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

    // Typed getters with validation
    function getNumber(key as Lang.String, defaultValue as Lang.Number) as Lang.Number {
        var value = get(key);
        if (value instanceof Number) {
            return value as Lang.Number;
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

    function getBoolean(key as Lang.String, defaultValue as Lang.Boolean) as Lang.Boolean {
        var value = get(key);
        if (value instanceof Boolean) {
            return value as Lang.Boolean;
        }
        return defaultValue;
    }

    function getString(key as Lang.String, defaultValue as Lang.String) as Lang.String {
        var value = get(key);
        if (value instanceof String) {
            return value as Lang.String;
        }
        return defaultValue;
    }

    // Time format settings
    function getTimeFormat() as Lang.Number {
        return getNumber("time_format", 24);
    }

    function setTimeFormat(format as Lang.Number) as Lang.Boolean {
        if (format == 12 || format == 24) {
            return set("time_format", format);
        }
        return false;
    }

    function shouldShowSeconds() as Lang.Boolean {
        return getBoolean("show_seconds", true);
    }

    function setShowSeconds(show as Lang.Boolean) as Lang.Boolean {
        return set("show_seconds", show);
    }

    function shouldShowDate() as Lang.Boolean {
        return getBoolean("show_date", true);
    }

    function setShowDate(show as Lang.Boolean) as Lang.Boolean {
        return set("show_date", show);
    }

    function getDateFormat() as Lang.String {
        return getString("date_format", "dd/mm/yyyy");
    }

    function setDateFormat(format as Lang.String) as Lang.Boolean {
        // Basic validation of date format
        if (format.length() > 0) {
            return set("date_format", format);
        }
        return false;
    }

    function getAutoUpdateInterval() as Lang.Number {
        return getNumber("auto_update_interval", 1);
    }

    function setAutoUpdateInterval(interval as Lang.Number) as Lang.Boolean {
        if (interval > 0 && interval <= 60) {
            return set("auto_update_interval", interval);
        }
        return false;
    }

    // Shabbat calculation settings
    function getCandleLightingOffset() as Lang.Number {
        return getNumber("candle_lighting_offset", 18);
    }

    function setCandleLightingOffset(offset as Lang.Number) as Lang.Boolean {
        if (offset >= 0 && offset <= 60) {
            return set("candle_lighting_offset", offset);
        }
        return false;
    }

    function getShabbatEndOffset() as Lang.Number {
        if (useRabbenuTam()) {
            return 72; // Fixed for Rabbenu Tam
        }
        return getNumber("shabbat_end_offset", 25);
    }

    function setShabbatEndOffset(offset as Lang.Number) as Lang.Boolean {
        if (offset >= 0 && offset <= 120) {
            return set("shabbat_end_offset", offset);
        }
        return false;
    }

    function useRabbenuTam() as Lang.Boolean {
        return getBoolean("use_rabbenu_tam", false);
    }

    function setUseRabbenuTam(use as Lang.Boolean) as Lang.Boolean {
        return set("use_rabbenu_tam", use);
    }

    // Tzais calculation method (FR-014).
    // Returns one of: "fixed_minutes", "degrees_8_5", "degrees_7_083".
    // When use_rabbenu_tam is true, returns "fixed_minutes" with shabbat_end_offset = 72.
    function getTzaisMethod() as Lang.String {
        if (useRabbenuTam()) {
            return "fixed_minutes";
        }
        return getString("tzais_method", "fixed_minutes");
    }

    function setTzaisMethod(method as Lang.String) as Lang.Boolean {
        if (method.equals("fixed_minutes") || method.equals("degrees_8_5") || method.equals("degrees_7_083")) {
            return set("tzais_method", method);
        }
        return false;
    }

    // Location settings
    function isAutoLocationEnabled() as Lang.Boolean {
        return getBoolean("auto_location", true);
    }

    function setAutoLocationEnabled(enabled as Lang.Boolean) as Lang.Boolean {
        return set("auto_location", enabled);
    }

    // Returns "gps" (default) or "manual" — semantic wrapper over auto_location.
    function getLocationSource() as Lang.String {
        return isAutoLocationEnabled() ? "gps" : "manual";
    }

    // Accepts "gps" or "manual"; anything else defaults to "gps".
    function setLocationSource(source as Lang.String) as Lang.Boolean {
        return setAutoLocationEnabled(!source.equals("manual"));
    }

    function getManualLatitude() as Lang.Float {
        return getFloat("manual_latitude", 0.0);
    }

    function getManualLongitude() as Lang.Float {
        return getFloat("manual_longitude", 0.0);
    }

    function setManualLocation(latitude as Lang.Float, longitude as Lang.Float) as Lang.Boolean {
        // Validate coordinates
        if (latitude >= -90.0 && latitude <= 90.0 &&
            longitude >= -180.0 && longitude <= 180.0) {

            var success1 = set("manual_latitude", latitude);
            var success2 = set("manual_longitude", longitude);
            return success1 && success2;
        }
        return false;
    }

    function isTimezoneAuto() as Lang.Boolean {
        return getBoolean("timezone_auto", true);
    }

    function setTimezoneAuto(auto as Lang.Boolean) as Lang.Boolean {
        return set("timezone_auto", auto);
    }

    function getManualTimezone() as Lang.String {
        return getString("timezone_manual", "UTC");
    }

    function setManualTimezone(timezone as Lang.String) as Lang.Boolean {
        if (timezone.length() > 0) {
            return set("timezone_manual", timezone);
        }
        return false;
    }

    function getLocationUpdateInterval() as Lang.Number {
        return getNumber("location_update_interval", 300);
    }

    function setLocationUpdateInterval(interval as Lang.Number) as Lang.Boolean {
        if (interval >= 30 && interval <= 3600) { // 30 seconds to 1 hour
            return set("location_update_interval", interval);
        }
        return false;
    }

    // Calculation preferences
    function getCalculationMethod() as Lang.String {
        return getString("calculation_method", "standard");
    }

    function setCalculationMethod(method as Lang.String) as Lang.Boolean {
        if (method.equals("standard") || method.equals("accurate") || method.equals("fast")) {
            return set("calculation_method", method);
        }
        return false;
    }

    function shouldUseElevationCorrection() as Lang.Boolean {
        return getBoolean("elevation_correction", true);
    }

    function setUseElevationCorrection(use as Lang.Boolean) as Lang.Boolean {
        return set("elevation_correction", use);
    }

    function shouldUseAtmosphericRefraction() as Lang.Boolean {
        return getBoolean("atmospheric_refraction", true);
    }

    function setUseAtmosphericRefraction(use as Lang.Boolean) as Lang.Boolean {
        return set("atmospheric_refraction", use);
    }

    function getPrecisionMinutes() as Lang.Number {
        return getNumber("precision_minutes", 1);
    }

    function setPrecisionMinutes(precision as Lang.Number) as Lang.Boolean {
        if (precision >= 1 && precision <= 10) {
            return set("precision_minutes", precision);
        }
        return false;
    }

    // Cache and performance settings
    function shouldCacheCalculations() as Lang.Boolean {
        return getBoolean("cache_calculations", true);
    }

    function setCacheCalculations(cache as Lang.Boolean) as Lang.Boolean {
        return set("cache_calculations", cache);
    }

    function getCacheDurationHours() as Lang.Number {
        return getNumber("cache_duration_hours", 24);
    }

    function setCacheDurationHours(hours as Lang.Number) as Lang.Boolean {
        if (hours >= 1 && hours <= 168) { // 1 hour to 1 week
            return set("cache_duration_hours", hours);
        }
        return false;
    }

    function shouldAllowBackgroundUpdates() as Lang.Boolean {
        return getBoolean("background_updates", true);
    }

    function setAllowBackgroundUpdates(allow as Lang.Boolean) as Lang.Boolean {
        return set("background_updates", allow);
    }

    function isLowPowerMode() as Lang.Boolean {
        return getBoolean("low_power_mode", false);
    }

    function setLowPowerMode(lowPower as Lang.Boolean) as Lang.Boolean {
        return set("low_power_mode", lowPower);
    }

    // Regional and custom settings
    function getRegion() as Lang.String {
        return getString("region", "standard");
    }

    function setRegion(region as Lang.String) as Lang.Boolean {
        if (region.equals("israel") || region.equals("diaspora") ||
            region.equals("custom") || region.equals("standard")) {
            return set("region", region);
        }
        return false;
    }

    function getStringencyLevel() as Lang.String {
        return getString("stringency_level", "moderate");
    }

    function setStringencyLevel(level as Lang.String) as Lang.Boolean {
        if (level.equals("strict") || level.equals("moderate") || level.equals("lenient")) {
            return set("stringency_level", level);
        }
        return false;
    }

    // Notification settings
    function areNotificationsEnabled() as Lang.Boolean {
        return getBoolean("notification_enabled", true);
    }

    function setNotificationsEnabled(enabled as Lang.Boolean) as Lang.Boolean {
        return set("notification_enabled", enabled);
    }

    function getNotificationMinutesBefore() as Lang.Number {
        return getNumber("notification_minutes_before", 10);
    }

    function setNotificationMinutesBefore(minutes as Lang.Number) as Lang.Boolean {
        if (minutes >= 0 && minutes <= 60) {
            return set("notification_minutes_before", minutes);
        }
        return false;
    }

    function isVibrationEnabled() as Lang.Boolean {
        return getBoolean("vibration_enabled", true);
    }

    function setVibrationEnabled(enabled as Lang.Boolean) as Lang.Boolean {
        return set("vibration_enabled", enabled);
    }

    function isSoundEnabled() as Lang.Boolean {
        return getBoolean("sound_enabled", false);
    }

    function setSoundEnabled(enabled as Lang.Boolean) as Lang.Boolean {
        return set("sound_enabled", enabled);
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

    function resetSetting(key as Lang.String) as Lang.Boolean {
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