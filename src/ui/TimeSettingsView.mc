using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Position;

// Settings screen for time-related preferences:
//   • Candle lighting offset (minutes before sunset, default 18)
//   • End-of-Shabbat offset in minutes (used when tzais method = fixed_minutes)
//   • Tzais method: fixed_minutes / degrees_8_5 (Geonim 8.5°) / degrees_7_083 (Geonim 7°)
//   • Time format (12h / 24h)
//   • Region: Israel / Diaspora (affects Parashat HaShavua calendar — FR-016)
//   • Location source: GPS / Manual (feature 004)
//   • Lat/Lon display — editable in Manual mode; read-only (shows cached GPS fix) in GPS mode
//   • Capture GPS — fires a one-shot GPS fix and saves it as the manual location
//
// Navigation: UP/DOWN cycle through settings items, SELECT toggles/increments.
class TimeSettingsView extends WatchUi.View {

    // Setting items shown in order
    private const ITEM_CANDLE_OFFSET    = 0;
    private const ITEM_END_OFFSET       = 1;
    private const ITEM_TZAIS_METHOD     = 2;
    private const ITEM_TIME_FORMAT      = 3;
    private const ITEM_REGION           = 4;
    private const ITEM_LOC_SOURCE       = 5;
    private const ITEM_LOC_LAT          = 6;
    private const ITEM_LOC_LON          = 7;
    private const ITEM_CAPTURE_GPS      = 8;
    private const ITEM_COUNT            = 9;

    private var _config as TimeConfiguration;
    private var _selectedItem as Lang.Number;
    private var _screenWidth as Lang.Number;
    private var _screenHeight as Lang.Number;
    // GPS capture state: "idle" | "acquiring" | "saved" | "failed"
    private var _gpsCaptureState as Lang.String;

    function initialize() {
        View.initialize();
        _config          = new TimeConfiguration();
        _selectedItem    = 0;
        _screenWidth     = 240;
        _screenHeight    = 240;
        _gpsCaptureState = "idle";
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        try {
            _screenWidth  = dc.getWidth();
            _screenHeight = dc.getHeight();

            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();

            _drawTitle(dc);
            _drawItems(dc);
            _drawHint(dc);

        } catch (ex instanceof Lang.Exception) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_screenWidth / 2, _screenHeight / 2,
                Graphics.FONT_SMALL,
                WatchUi.loadResource(Rez.Strings.SettingsError) as Lang.String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function selectNext() as Void {
        _selectedItem = (_selectedItem + 1) % ITEM_COUNT;
        WatchUi.requestUpdate();
    }

    function selectPrev() as Void {
        _selectedItem = (_selectedItem + ITEM_COUNT - 1) % ITEM_COUNT;
        WatchUi.requestUpdate();
    }

    function activateSelected() as Void {
        switch (_selectedItem) {
            case ITEM_CANDLE_OFFSET:
                var newCandle = _config.getCandleLightingOffset() + 1;
                if (newCandle > 40) { newCandle = 10; }
                _config.setCandleLightingOffset(newCandle);
                break;
            case ITEM_END_OFFSET:
                var newEnd = _config.getShabbatEndOffset() + 5;
                if (newEnd > 90) { newEnd = 20; }
                _config.setShabbatEndOffset(newEnd);
                break;
            case ITEM_TZAIS_METHOD:
                var currentMethod = _config.getTzaisMethod();
                var nextMethod = "fixed_minutes";
                if (currentMethod.equals("fixed_minutes"))  { nextMethod = "degrees_8_5"; }
                else if (currentMethod.equals("degrees_8_5")) { nextMethod = "degrees_7_083"; }
                _config.setTzaisMethod(nextMethod);
                break;
            case ITEM_TIME_FORMAT:
                var fmt = _config.getTimeFormat();
                _config.setTimeFormat(fmt == 24 ? 12 : 24);
                break;
            case ITEM_REGION:
                var region = _config.getRegion();
                _config.setRegion(region.equals("israel") ? "diaspora" : "israel");
                break;
            case ITEM_LOC_SOURCE:
                var src = _config.getLocationSource();
                _config.setLocationSource(src.equals("gps") ? "manual" : "gps");
                _persistLocation(); // persist source change immediately (SC-001)
                break;
            case ITEM_LOC_LAT:
                // Read-only in GPS mode — lat shows the cached GPS value.
                if (_config.getLocationSource().equals("gps")) { break; }
                // Increment latitude by 1°; wrap at poles.
                var lat = _config.getManualLatitude().toNumber();
                lat = lat + 1;
                if (lat > 90) { lat = -90; }
                _config.setManualLocation(lat.toFloat(), _config.getManualLongitude());
                _persistLocation(); // persist each degree change (FR-003, SC-001)
                break;
            case ITEM_LOC_LON:
                // Read-only in GPS mode — lon shows the cached GPS value.
                if (_config.getLocationSource().equals("gps")) { break; }
                // Increment longitude by 1°; wrap at antimeridian.
                var lon = _config.getManualLongitude().toNumber();
                lon = lon + 1;
                if (lon > 180) { lon = -180; }
                _config.setManualLocation(_config.getManualLatitude(), lon.toFloat());
                _persistLocation(); // persist each degree change (FR-003, SC-001)
                break;
            case ITEM_CAPTURE_GPS:
                // Fire a one-shot GPS acquisition; UI shows "Acquiring…" until callback fires.
                try {
                    Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onGpsFix));
                    _gpsCaptureState = "acquiring";
                } catch (ex instanceof Lang.Exception) {
                    _gpsCaptureState = "failed";
                }
                break;
        }
        WatchUi.requestUpdate();
    }

    // Callback fired by Position.enableLocationEvents(LOCATION_ONE_SHOT, ...) once
    // a GPS fix is available.  Persists the fix as manual coordinates and switches
    // the location source to "manual" so the coordinates are immediately used.
    function onGpsFix(info as Position.Info) as Void {
        try {
            if (info != null && info.position != null) {
                var coords = info.position.toDegrees();
                if (coords != null && coords.size() >= 2) {
                    var fixLat = coords[0].toFloat();
                    var fixLon = coords[1].toFloat();
                    if (LocationValidator.isUsable(fixLat, fixLon)) {
                        // Persist directly to Application.Storage so the value
                        // survives beyond this in-memory config instance.
                        var storage = new StorageManager();
                        storage.initialize();
                        var settings = storage.getUserSettings();
                        if (settings == null) {
                            settings = {} as Lang.Dictionary<Lang.String, Lang.Object>;
                        }
                        settings.put("location_auto", false);
                        settings.put("latitude",  fixLat);
                        settings.put("longitude", fixLon);
                        // Also update TimeConfiguration keys for _tryManual() fallback.
                        settings.put("manual_latitude",  fixLat);
                        settings.put("manual_longitude", fixLon);
                        storage.saveUserSettings(settings);

                        // Mirror into the in-memory config so the view redraws immediately.
                        _config.setManualLocation(fixLat, fixLon);
                        _config.setLocationSource("manual");

                        _gpsCaptureState = "saved";
                    } else {
                        _gpsCaptureState = "failed";
                    }
                } else {
                    _gpsCaptureState = "failed";
                }
            } else {
                _gpsCaptureState = "failed";
            }
        } catch (ex instanceof Lang.Exception) {
            _gpsCaptureState = "failed";
        }
        WatchUi.requestUpdate();
    }

    // Persist the current location settings (_config) to Application.Storage so
    // that manual coordinates and source selection survive an app restart (SC-001,
    // FR-003).  Uses the same canonical keys written by onGpsFix() so that
    // LocationService._tryManual() and _isManualSourceConfigured() read correctly.
    private function _persistLocation() as Void {
        try {
            var storage = new StorageManager();
            storage.initialize();
            var settings = storage.getUserSettings();
            if (settings == null) {
                settings = {} as Lang.Dictionary<Lang.String, Lang.Object>;
            }
            var isManual = _config.getLocationSource().equals("manual");
            settings.put("location_auto", !isManual);
            var saveLat = _config.getManualLatitude();
            var saveLon = _config.getManualLongitude();
            settings.put("latitude",         saveLat);
            settings.put("longitude",        saveLon);
            settings.put("manual_latitude",  saveLat);
            settings.put("manual_longitude", saveLon);
            storage.saveUserSettings(settings);
        } catch (ex instanceof Lang.Exception) {
            // Storage failure is non-fatal — in-memory config remains valid.
        }
    }

    // -------------------------------------------------------------------------
    // Drawing
    // -------------------------------------------------------------------------

    private function _drawTitle(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_screenWidth / 2, _screenHeight / 10,
            Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.SettingsTitle) as Lang.String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(10, _screenHeight / 6, _screenWidth - 10, _screenHeight / 6);
    }

    private function _drawItems(dc as Graphics.Dc) as Void {
        var startY  = _screenHeight / 5;
        var rowH    = (_screenHeight - startY - _screenHeight / 10) / ITEM_COUNT;

        var tzaisMethod = _config.getTzaisMethod();
        var tzaisLabel  = WatchUi.loadResource(Rez.Strings.TzaisFixed) as Lang.String;
        if (tzaisMethod.equals("degrees_8_5"))   { tzaisLabel = WatchUi.loadResource(Rez.Strings.TzaisGeonim8_5)   as Lang.String; }
        if (tzaisMethod.equals("degrees_7_083")) { tzaisLabel = WatchUi.loadResource(Rez.Strings.TzaisGeonim7_083) as Lang.String; }

        var regionName = _config.getRegion().equals("israel")
            ? (WatchUi.loadResource(Rez.Strings.RegionIsrael) as Lang.String)
            : (WatchUi.loadResource(Rez.Strings.RegionDiaspora) as Lang.String);

        var locSource    = _config.getLocationSource();
        var isGpsMode   = !locSource.equals("manual");
        var locSrcLabel  = isGpsMode
            ? (WatchUi.loadResource(Rez.Strings.LocationSourceGps) as Lang.String)
            : (WatchUi.loadResource(Rez.Strings.LocationSourceManual) as Lang.String);

        // Resolve the coordinates shown on the lat/lon rows.
        // GPS mode: read from LocationCache (the live/cached GPS fix).
        // Manual mode: read from _config (the user-entered values).
        var displayLat  = 0.0;
        var displayLon  = 0.0;
        var hasDisplayCoords = false;
        if (isGpsMode) {
            var cache = new LocationCache();
            if (cache.hasValidCache()) {
                displayLat = cache.getCachedLatitude();
                displayLon = cache.getCachedLongitude();
                hasDisplayCoords = true;
            }
        } else {
            displayLat = _config.getManualLatitude();
            displayLon = _config.getManualLongitude();
            hasDisplayCoords = (displayLat != 0.0 || displayLon != 0.0);
        }

        var latStr = hasDisplayCoords ? displayLat.format("%d") : "--";
        var lonStr = hasDisplayCoords ? displayLon.format("%d") : "--";
        // Append polar warning when latitude is in the Arctic/Antarctic range.
        if (hasDisplayCoords && LocationValidator.isPolarRegion(displayLat)) {
            latStr = latStr + "! (polar)";
        }

        // GPS capture row label reflects the current acquisition state.
        var captureLabel = WatchUi.loadResource(Rez.Strings.CaptureGpsLabel) as Lang.String;
        if (_gpsCaptureState.equals("acquiring")) {
            captureLabel = WatchUi.loadResource(Rez.Strings.CapturingGpsLabel) as Lang.String;
        } else if (_gpsCaptureState.equals("saved")) {
            captureLabel = WatchUi.loadResource(Rez.Strings.GpsCapturedLabel) as Lang.String;
        } else if (_gpsCaptureState.equals("failed")) {
            captureLabel = WatchUi.loadResource(Rez.Strings.GpsCaptureFailed) as Lang.String;
        }

        var labels = [
            Lang.format(WatchUi.loadResource(Rez.Strings.CandlesSettingFormat) as Lang.String,
                [_config.getCandleLightingOffset().format("%d")]),
            Lang.format(WatchUi.loadResource(Rez.Strings.ShabbatEndSettingFormat) as Lang.String,
                [_config.getShabbatEndOffset().format("%d")]),
            (WatchUi.loadResource(Rez.Strings.TzaisMethodLabel) as Lang.String) + " " + tzaisLabel,
            Lang.format(WatchUi.loadResource(Rez.Strings.TimeFormatSettingFormat) as Lang.String,
                [_config.getTimeFormat().format("%d")]),
            (WatchUi.loadResource(Rez.Strings.RegionLabel) as Lang.String) + " " + regionName,
            Lang.format(WatchUi.loadResource(Rez.Strings.LocationSourceSettingFormat) as Lang.String,
                [locSrcLabel]),
            Lang.format(WatchUi.loadResource(Rez.Strings.LatitudeSettingFormat) as Lang.String,
                [latStr]),
            Lang.format(WatchUi.loadResource(Rez.Strings.LongitudeSettingFormat) as Lang.String,
                [lonStr]),
            captureLabel
        ];

        for (var i = 0; i < ITEM_COUNT; i++) {
            var y = startY + i * rowH + rowH / 2;
            var isSelected = (i == _selectedItem);

            // Lat/lon rows are read-only in GPS mode — dim slightly to signal that.
            // Capture row dims while acquisition is in-flight.
            var isReadOnly = (i == ITEM_LOC_LAT || i == ITEM_LOC_LON) && isGpsMode;
            var isBusy     = (i == ITEM_CAPTURE_GPS) && _gpsCaptureState.equals("acquiring");

            if (isSelected) {
                dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(5, startY + i * rowH, _screenWidth - 10, rowH - 2);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            } else if (isReadOnly || isBusy) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            }

            dc.drawText(_screenWidth / 2, y, Graphics.FONT_SMALL, labels[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function _drawHint(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_screenWidth / 2, _screenHeight - _screenHeight / 12,
            Graphics.FONT_TINY,
            WatchUi.loadResource(Rez.Strings.SettingsHint) as Lang.String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

// Input delegate for TimeSettingsView.
class TimeSettingsDelegate extends WatchUi.BehaviorDelegate {

    private var _view as TimeSettingsView;

    function initialize(view as TimeSettingsView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Lang.Boolean {
        _view.selectNext();
        return true;
    }

    function onPreviousPage() as Lang.Boolean {
        _view.selectPrev();
        return true;
    }

    function onSelect() as Lang.Boolean {
        _view.activateSelected();
        return true;
    }

    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
