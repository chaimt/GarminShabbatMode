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

    // String validation
    static function validateString(value as Object?, allowEmpty as Boolean) as Number {
        if (value == null) {
            return INVALID_NULL;
        }

        if (!(value instanceof String)) {
            return INVALID_TYPE;
        }

        var stringValue = value as String;
        if (stringValue.length() == 0 && !allowEmpty) {
            return INVALID_EMPTY;
        }

        return VALID;
    }

    static function validateStringLength(value as String, minLength as Number, maxLength as Number) as Number {
        if (value.length() < minLength || value.length() > maxLength) {
            return INVALID_RANGE;
        }
        return VALID;
    }

    // Number validation
    static function validateNumber(value as Object?) as Number {
        if (value == null) {
            return INVALID_NULL;
        }

        if (!(value instanceof Number || value instanceof Float || value instanceof Long)) {
            return INVALID_TYPE;
        }

        return VALID;
    }

    static function validateNumberRange(value as Number, min as Number, max as Number) as Number {
        if (value < min || value > max) {
            return INVALID_RANGE;
        }
        return VALID;
    }

    // Boolean validation
    static function validateBoolean(value as Object?) as Number {
        if (value == null) {
            return INVALID_NULL;
        }

        if (!(value instanceof Boolean)) {
            return INVALID_TYPE;
        }

        return VALID;
    }

    // Dictionary validation
    static function validateDictionary(value as Object?) as Number {
        if (value == null) {
            return INVALID_NULL;
        }

        if (!(value instanceof Dictionary)) {
            return INVALID_TYPE;
        }

        return VALID;
    }

    static function validateDictionaryKey(dict as Dictionary<String, Object>, key as String, required as Boolean) as Number {
        if (!dict.hasKey(key)) {
            return required ? INVALID_FORMAT : VALID;
        }
        return VALID;
    }

    // Array validation
    static function validateArray(value as Object?) as Number {
        if (value == null) {
            return INVALID_NULL;
        }

        if (!(value instanceof Array)) {
            return INVALID_TYPE;
        }

        return VALID;
    }

    static function validateArraySize(value as Array<Object>, minSize as Number, maxSize as Number) as Number {
        if (value.size() < minSize || value.size() > maxSize) {
            return INVALID_RANGE;
        }
        return VALID;
    }

    // Specialized validation methods
    static function validateCoordinates(latitude as Object?, longitude as Object?) as Number {
        // Validate latitude
        var latResult = validateNumber(latitude);
        if (latResult != VALID) {
            return latResult;
        }

        var latValue = latitude as Number;
        if (latValue < -90.0 || latValue > 90.0) {
            return INVALID_RANGE;
        }

        // Validate longitude
        var lonResult = validateNumber(longitude);
        if (lonResult != VALID) {
            return lonResult;
        }

        var lonValue = longitude as Number;
        if (lonValue < -180.0 || lonValue > 180.0) {
            return INVALID_RANGE;
        }

        return VALID;
    }

    static function validateTimeFormat(timeString as String) as Number {
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
    static function isValid(result as Number) as Boolean {
        return result == VALID;
    }

    static function getValidationErrorMessage(result as Number) as String {
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