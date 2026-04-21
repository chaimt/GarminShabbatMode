using Toybox.Lang;

class Validator {

    // Validation result constants
    static const VALID = 0;
    static const INVALID_NULL = 1;
    static const INVALID_EMPTY = 2;
    static const INVALID_TYPE = 3;
    static const INVALID_RANGE = 4;
    static const INVALID_FORMAT = 5;

    function initialize() {
        // Static utility class - no initialization needed
    }

    // Lang.String validation
    static function validateString(value as Lang.Object?, allowEmpty as Lang.Boolean) as Lang.Number {
        if (value == null) {
            return INVALID_NULL;
        }

        if (!(value instanceof String)) {
            return INVALID_TYPE;
        }

        var stringValue = value as Lang.String;
        if (stringValue.length() == 0 && !allowEmpty) {
            return INVALID_EMPTY;
        }

        return VALID;
    }

    static function validateStringLength(value as Lang.String, minLength as Lang.Number, maxLength as Lang.Number) as Lang.Number {
        if (value.length() < minLength || value.length() > maxLength) {
            return INVALID_RANGE;
        }
        return VALID;
    }

    // Lang.Number validation
    static function validateNumber(value as Lang.Object?) as Lang.Number {
        if (value == null) {
            return INVALID_NULL;
        }

        if (!(value instanceof Lang.Number || value instanceof Lang.Float || value instanceof Long)) {
            return INVALID_TYPE;
        }

        return VALID;
    }

    static function validateNumberRange(value as Lang.Number, min as Lang.Number, max as Lang.Number) as Lang.Number {
        if (value < min || value > max) {
            return INVALID_RANGE;
        }
        return VALID;
    }

    // Lang.Boolean validation
    static function validateBoolean(value as Lang.Object?) as Lang.Number {
        if (value == null) {
            return INVALID_NULL;
        }

        if (!(value instanceof Boolean)) {
            return INVALID_TYPE;
        }

        return VALID;
    }

    // Lang.Dictionary validation
    static function validateDictionary(value as Lang.Object?) as Lang.Number {
        if (value == null) {
            return INVALID_NULL;
        }

        if (!(value instanceof Dictionary)) {
            return INVALID_TYPE;
        }

        return VALID;
    }

    static function validateDictionaryKey(dict as Lang.Dictionary<Lang.String, Lang.Object>, key as Lang.String, required as Lang.Boolean) as Lang.Number {
        if (!dict.hasKey(key)) {
            return required ? INVALID_FORMAT : VALID;
        }
        return VALID;
    }

    // Lang.Array validation
    static function validateArray(value as Lang.Object?) as Lang.Number {
        if (value == null) {
            return INVALID_NULL;
        }

        if (!(value instanceof Array)) {
            return INVALID_TYPE;
        }

        return VALID;
    }

    static function validateArraySize(value as Lang.Array<Lang.Object>, minSize as Lang.Number, maxSize as Lang.Number) as Lang.Number {
        if (value.size() < minSize || value.size() > maxSize) {
            return INVALID_RANGE;
        }
        return VALID;
    }

    // Specialized validation methods
    static function validateCoordinates(latitude as Lang.Object?, longitude as Lang.Object?) as Lang.Number {
        // Validate latitude
        var latResult = validateNumber(latitude);
        if (latResult != VALID) {
            return latResult;
        }

        var latValue = latitude as Lang.Number;
        if (latValue < -90.0 || latValue > 90.0) {
            return INVALID_RANGE;
        }

        // Validate longitude
        var lonResult = validateNumber(longitude);
        if (lonResult != VALID) {
            return lonResult;
        }

        var lonValue = longitude as Lang.Number;
        if (lonValue < -180.0 || lonValue > 180.0) {
            return INVALID_RANGE;
        }

        return VALID;
    }

    static function validateTimeFormat(timeString as Lang.String) as Lang.Number {
        // Basic time format validation (HH:MM)
        if (timeString.length() != 5) {
            return INVALID_FORMAT;
        }

        if (timeString.substring(2, 3) != ":") {
            return INVALID_FORMAT;
        }

        // This is a simplified validation - could be expanded
        return VALID;
    }

    // Validation result helpers
    static function isValid(result as Lang.Number) as Lang.Boolean {
        return result == VALID;
    }

    static function getValidationErrorMessage(result as Lang.Number) as Lang.String {
        switch (result) {
            case VALID:
                return "Valid";
            case INVALID_NULL:
                return "Value cannot be null";
            case INVALID_EMPTY:
                return "Value cannot be empty";
            case INVALID_TYPE:
                return "Invalid type";
            case INVALID_RANGE:
                return "Value out of range";
            case INVALID_FORMAT:
                return "Invalid format";
            default:
                return "Unknown validation error";
        }
    }
}