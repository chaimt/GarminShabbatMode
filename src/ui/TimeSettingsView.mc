using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;

// Settings screen for time-related preferences:
//   • Candle lighting offset (minutes before sunset, default 18)
//   • End-of-Shabbat offset in minutes (used when tzais method = fixed_minutes)
//   • Tzais method: fixed_minutes / degrees_8_5 (Geonim 8.5°) / degrees_7_083 (Geonim 7°)
//   • Time format (12h / 24h)
//   • Region: Israel / Diaspora (affects Parashat HaShavua calendar — FR-016)
//
// Navigation: UP/DOWN cycle through settings items, SELECT toggles/increments.
class TimeSettingsView extends WatchUi.View {

    // Setting items shown in order
    private const ITEM_CANDLE_OFFSET    = 0;
    private const ITEM_END_OFFSET       = 1;
    private const ITEM_TZAIS_METHOD     = 2;
    private const ITEM_TIME_FORMAT      = 3;
    private const ITEM_REGION           = 4;
    private const ITEM_COUNT            = 5;

    // Ordered tzais method values matching TzaisFixed / TzaisGeonim8_5 / TzaisGeonim7_083
    private const TZAIS_METHODS = ["fixed_minutes", "degrees_8_5", "degrees_7_083"];

    private var _config as TimeConfiguration;
    private var _selectedItem as Lang.Number;
    private var _screenWidth as Lang.Number;
    private var _screenHeight as Lang.Number;

    function initialize() {
        View.initialize();
        _config       = new TimeConfiguration();
        _selectedItem = 0;
        _screenWidth  = 240;
        _screenHeight = 240;
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
        }
        WatchUi.requestUpdate();
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

        var labels = [
            Lang.format(WatchUi.loadResource(Rez.Strings.CandlesSettingFormat) as Lang.String,
                [_config.getCandleLightingOffset().format("%d")]),
            Lang.format(WatchUi.loadResource(Rez.Strings.ShabbatEndSettingFormat) as Lang.String,
                [_config.getShabbatEndOffset().format("%d")]),
            (WatchUi.loadResource(Rez.Strings.TzaisMethodLabel) as Lang.String) + " " + tzaisLabel,
            Lang.format(WatchUi.loadResource(Rez.Strings.TimeFormatSettingFormat) as Lang.String,
                [_config.getTimeFormat().format("%d")]),
            (WatchUi.loadResource(Rez.Strings.RegionLabel) as Lang.String) + " " + regionName
        ];

        for (var i = 0; i < ITEM_COUNT; i++) {
            var y = startY + i * rowH + rowH / 2;
            var isSelected = (i == _selectedItem);

            if (isSelected) {
                dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(5, startY + i * rowH, _screenWidth - 10, rowH - 2);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
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
