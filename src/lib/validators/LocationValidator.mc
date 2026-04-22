using Toybox.Lang;
using Toybox.Math;

// Validates GPS coordinate values and detects polar/extreme-latitude conditions.
class LocationValidator {

    // Latitude must be in [-90, 90].
    static function isValidLatitude(lat as Lang.Float) as Lang.Boolean {
        return lat >= -90.0 && lat <= 90.0;
    }

    // Longitude must be in [-180, 180].
    static function isValidLongitude(lon as Lang.Float) as Lang.Boolean {
        return lon >= -180.0 && lon <= 180.0;
    }

    // Returns true when |lat| > 66.5° (Arctic/Antarctic circles).
    // Astronomical sunset/sunrise calculations are unreliable in these regions.
    static function isPolarRegion(lat as Lang.Float) as Lang.Boolean {
        var absLat = lat;
        if (absLat < 0.0) { absLat = -absLat; }
        return absLat > 66.5;
    }

    // Returns true when |lat| > 48.5° (higher-latitude urban areas like London,
    // Moscow, etc.) where twilight calculations may need special treatment.
    static function isHighLatitude(lat as Lang.Float) as Lang.Boolean {
        var absLat = lat;
        if (absLat < 0.0) { absLat = -absLat; }
        return absLat > 48.5;
    }

    // Full coordinate-pair validation.
    static function isValidCoordinates(lat as Lang.Float, lon as Lang.Float) as Lang.Boolean {
        return isValidLatitude(lat) && isValidLongitude(lon);
    }

    // Non-zero coordinate check (zero/zero is the Gulf of Guinea — unlikely to be intentional).
    static function isNonZero(lat as Lang.Float, lon as Lang.Float) as Lang.Boolean {
        return lat != 0.0 || lon != 0.0;
    }

    // Combined: valid and likely intentional.
    static function isUsable(lat as Lang.Float, lon as Lang.Float) as Lang.Boolean {
        return isValidCoordinates(lat, lon) && isNonZero(lat, lon);
    }
}
