using Toybox.Position;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Time;

class Location {

    private var _latitude as Lang.Float;
    private var _longitude as Lang.Float;
    private var _altitude as Lang.Float?;
    private var _accuracy as Lang.Number?;
    private var _timestamp as Time.Moment?;
    private var _isValid as Lang.Boolean;
    private var _source as Lang.String;
    private var _city as Lang.String?;
    private var _country as Lang.String?;

    function initialize() {
        _latitude = 0.0;
        _longitude = 0.0;
        _altitude = null;
        _accuracy = null;
        _timestamp = null;
        _isValid = false;
        _source = "unknown";
        _city = null;
        _country = null;
    }

    // Position setters
    function setPosition(latitude as Lang.Float, longitude as Lang.Float) as Lang.Boolean {
        if (validateCoordinates(latitude, longitude)) {
            _latitude = latitude;
            _longitude = longitude;
            _timestamp = Time.now();
            _isValid = true;
            return true;
        }
        return false;
    }

    function setPositionWithAltitude(latitude as Lang.Float, longitude as Lang.Float, altitude as Lang.Float) as Lang.Boolean {
        var success = setPosition(latitude, longitude);
        if (success) {
            _altitude = altitude;
        }
        return success;
    }

    function setFromPositionInfo(positionInfo as Position.Info) as Lang.Boolean {
        try {
            if (positionInfo.position != null) {
                var pos = positionInfo.position;
                var lat = pos.toDegrees()[0];
                var lon = pos.toDegrees()[1];

                if (validateCoordinates(lat, lon)) {
                    _latitude = lat;
                    _longitude = lon;
                    _accuracy = positionInfo.accuracy;
                    _timestamp = Time.now();
                    _isValid = true;
                    _source = "gps";

                    // Set altitude if available
                    if (positionInfo.altitude != null) {
                        _altitude = positionInfo.altitude;
                    }

                    return true;
                }
            }
        } catch (ex instanceof Lang.Exception) {
            _isValid = false;
        }

        return false;
    }

    // Getters
    function getLatitude() as Lang.Float {
        return _latitude;
    }

    function getLongitude() as Lang.Float {
        return _longitude;
    }

    function getAltitude() as Lang.Float? {
        return _altitude;
    }

    function getAccuracy() as Lang.Number? {
        return _accuracy;
    }

    function getTimestamp() as Time.Moment? {
        return _timestamp;
    }

    function isValid() as Lang.Boolean {
        return _isValid;
    }

    function getSource() as Lang.String {
        return _source;
    }

    function setSource(source as Lang.String) as Void {
        _source = source;
    }

    // Location metadata
    function getCity() as Lang.String? {
        return _city;
    }

    function setCity(city as Lang.String) as Void {
        _city = city;
    }

    function getCountry() as Lang.String? {
        return _country;
    }

    function setCountry(country as Lang.String) as Void {
        _country = country;
    }

    // Coordinate validation
    private function validateCoordinates(lat as Lang.Float, lon as Lang.Float) as Lang.Boolean {
        return (lat >= -90.0 && lat <= 90.0 &&
                lon >= -180.0 && lon <= 180.0);
    }

    // Distance calculations
    function distanceTo(otherLocation as Location) as Lang.Float? {
        if (!_isValid || !otherLocation.isValid()) {
            return null;
        }

        // Haversine formula for great-circle distance
        var lat1Rad = Math.toRadians(_latitude);
        var lon1Rad = Math.toRadians(_longitude);
        var lat2Rad = Math.toRadians(otherLocation.getLatitude());
        var lon2Rad = Math.toRadians(otherLocation.getLongitude());

        var deltaLat = lat2Rad - lat1Rad;
        var deltaLon = lon2Rad - lon1Rad;

        var a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
                Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);

        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        // Earth radius in meters
        var earthRadius = 6371000.0;
        return earthRadius * c;
    }

    function bearingTo(otherLocation as Location) as Lang.Float? {
        if (!_isValid || !otherLocation.isValid()) {
            return null;
        }

        var lat1Rad = Math.toRadians(_latitude);
        var lat2Rad = Math.toRadians(otherLocation.getLatitude());
        var deltaLonRad = Math.toRadians(otherLocation.getLongitude() - _longitude);

        var y = Math.sin(deltaLonRad) * Math.cos(lat2Rad);
        var x = Math.cos(lat1Rad) * Math.sin(lat2Rad) -
                Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(deltaLonRad);

        var bearingRad = Math.atan2(y, x);
        var bearingDeg = Math.toDegrees(bearingRad);

        // Normalize to 0-360 degrees
        return (bearingDeg + 360.0) % 360.0;
    }

    // Location comparison
    function isNear(otherLocation as Location, toleranceMeters as Lang.Float) as Lang.Boolean {
        var distance = distanceTo(otherLocation);
        return (distance != null && distance <= toleranceMeters);
    }

    function equals(otherLocation as Location, precision as Lang.Float) as Lang.Boolean {
        if (!_isValid || !otherLocation.isValid()) {
            return false;
        }

        var latDiff = Math.abs(_latitude - otherLocation.getLatitude());
        var lonDiff = Math.abs(_longitude - otherLocation.getLongitude());

        return (latDiff <= precision && lonDiff <= precision);
    }

    // Age and freshness
    function getAgeInSeconds() as Lang.Number? {
        if (_timestamp != null) {
            var now = Time.now();
            return now.subtract(_timestamp).value();
        }
        return null;
    }

    function isStale(maxAgeSeconds as Lang.Number) as Lang.Boolean {
        var age = getAgeInSeconds();
        return (age == null || age > maxAgeSeconds);
    }

    // Formatted output
    function toString() as Lang.String {
        return Lang.format("($1$, $2$)", [
            _latitude.format("%.6f"),
            _longitude.format("%.6f")
        ]);
    }

    function toDegreesMinutesString() as Lang.String {
        var latDeg = Math.floor(Math.abs(_latitude));
        var latMin = (Math.abs(_latitude) - latDeg) * 60.0;
        var latDir = _latitude >= 0 ? "N" : "S";

        var lonDeg = Math.floor(Math.abs(_longitude));
        var lonMin = (Math.abs(_longitude) - lonDeg) * 60.0;
        var lonDir = _longitude >= 0 ? "E" : "W";

        return Lang.format("$1$°$2$'$3$ $4$°$5$'$6$", [
            latDeg,
            latMin.format("%.2f"),
            latDir,
            lonDeg,
            lonMin.format("%.2f"),
            lonDir
        ]);
    }

    // Coordinate conversion helpers
    function toRadians() as Lang.Array<Lang.Float> {
        return [Math.toRadians(_latitude), Math.toRadians(_longitude)];
    }

    function toDegrees() as Lang.Array<Lang.Float> {
        return [_latitude, _longitude];
    }

    // Storage and serialization
    function toDict() as Lang.Dictionary<Lang.String, Lang.Object> {
        return {
            "latitude" => _latitude,
            "longitude" => _longitude,
            "altitude" => _altitude,
            "accuracy" => _accuracy,
            "timestamp" => _timestamp != null ? _timestamp.value() : 0,
            "is_valid" => _isValid,
            "source" => _source,
            "city" => _city,
            "country" => _country
        } as Lang.Dictionary<Lang.String, Lang.Object>;
    }

    function fromDict(dict as Lang.Dictionary<Lang.String, Lang.Object>) as Lang.Boolean {
        try {
            if (dict.hasKey("latitude") && dict.hasKey("longitude")) {
                var lat = dict.get("latitude");
                var lon = dict.get("longitude");

                if (lat instanceof Lang.Float && lon instanceof Lang.Float) {
                    _latitude = lat as Lang.Float;
                    _longitude = lon as Lang.Float;
                    _isValid = validateCoordinates(_latitude, _longitude);

                    if (dict.hasKey("altitude")) {
                        _altitude = dict.get("altitude");
                    }
                    if (dict.hasKey("accuracy")) {
                        _accuracy = dict.get("accuracy");
                    }
                    if (dict.hasKey("timestamp") && dict.get("timestamp") instanceof Number) {
                        _timestamp = new Time.Moment(dict.get("timestamp") as Lang.Number);
                    }
                    if (dict.hasKey("source")) {
                        _source = dict.get("source") as Lang.String;
                    }
                    if (dict.hasKey("city")) {
                        _city = dict.get("city");
                    }
                    if (dict.hasKey("country")) {
                        _country = dict.get("country");
                    }

                    return true;
                }
            }
        } catch (ex instanceof Lang.Exception) {
            // Failed to parse
        }

        return false;
    }

    // Static factory methods
    static function fromCoordinates(latitude as Lang.Float, longitude as Lang.Float) as Location {
        var loc = new Location();
        loc.setPosition(latitude, longitude);
        return loc;
    }

    static function fromGPS(positionInfo as Position.Info) as Location? {
        var location = new Location();
        if (location.setFromPositionInfo(positionInfo)) {
            return location;
        }
        return null;
    }

    // Common locations for testing
    static function getJerusalem() as Location {
        return fromCoordinates(31.7683, 35.2137);
    }

    static function getNewYork() as Location {
        return fromCoordinates(40.7128, -74.0060);
    }

    static function getLondon() as Location {
        return fromCoordinates(51.5074, -0.1278);
    }
}