using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

class BaseComponent {

    private var _x as Lang.Number;
    private var _y as Lang.Number;
    private var _width as Lang.Number;
    private var _height as Lang.Number;
    private var _visible as Lang.Boolean;
    private var _enabled as Lang.Boolean;
    private var _backgroundColor as Lang.Number;
    private var _textColor as Lang.Number;
    private var _borderColor as Lang.Number;
    private var _padding as Lang.Number;

    function initialize(x as Lang.Number, y as Lang.Number, width as Lang.Number, height as Lang.Number) {
        _x = x;
        _y = y;
        _width = width;
        _height = height;
        _visible = true;
        _enabled = true;
        _backgroundColor = Graphics.COLOR_TRANSPARENT;
        _textColor = Graphics.COLOR_WHITE;
        _borderColor = Graphics.COLOR_TRANSPARENT;
        _padding = 5;
    }

    // Position and size methods
    function setPosition(x as Lang.Number, y as Lang.Number) as Void {
        _x = x;
        _y = y;
    }

    function getX() as Lang.Number {
        return _x;
    }

    function getY() as Lang.Number {
        return _y;
    }

    function setSize(width as Lang.Number, height as Lang.Number) as Void {
        _width = width;
        _height = height;
    }

    function getWidth() as Lang.Number {
        return _width;
    }

    function getHeight() as Lang.Number {
        return _height;
    }

    function getBounds() as Lang.Dictionary<Lang.String, Lang.Number> {
        return {
            "x" => _x,
            "y" => _y,
            "width" => _width,
            "height" => _height
        } as Lang.Dictionary<Lang.String, Lang.Number>;
    }

    // Visibility and state methods
    function setVisible(visible as Lang.Boolean) as Void {
        _visible = visible;
    }

    function isVisible() as Lang.Boolean {
        return _visible;
    }

    function setEnabled(enabled as Lang.Boolean) as Void {
        _enabled = enabled;
    }

    function isEnabled() as Lang.Boolean {
        return _enabled;
    }

    // Styling methods
    function setBackgroundColor(color as Lang.Number) as Void {
        _backgroundColor = color;
    }

    function getBackgroundColor() as Lang.Number {
        return _backgroundColor;
    }

    function setTextColor(color as Lang.Number) as Void {
        _textColor = color;
    }

    function getTextColor() as Lang.Number {
        return _textColor;
    }

    function setBorderColor(color as Lang.Number) as Void {
        _borderColor = color;
    }

    function getBorderColor() as Lang.Number {
        return _borderColor;
    }

    function setPadding(padding as Lang.Number) as Void {
        _padding = padding;
    }

    function getPadding() as Lang.Number {
        return _padding;
    }

    // Hit testing
    function containsPoint(x as Lang.Number, y as Lang.Number) as Lang.Boolean {
        return x >= _x && x <= (_x + _width) &&
               y >= _y && y <= (_y + _height);
    }

    // Drawing methods (to be overridden by subclasses)
    function draw(dc as Graphics.Dc) as Void {
        if (!_visible) {
            return;
        }

        // Draw background if specified
        if (_backgroundColor != Graphics.COLOR_TRANSPARENT) {
            dc.setColor(_backgroundColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(_x, _y, _width, _height);
        }

        // Draw border if specified
        if (_borderColor != Graphics.COLOR_TRANSPARENT) {
            dc.setColor(_borderColor, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(_x, _y, _width, _height);
        }

        // Override in subclasses for specific drawing
        drawContent(dc);
    }

    // To be overridden by subclasses
    protected function drawContent(dc as Graphics.Dc) as Void {
        // Base implementation does nothing
    }

    // Event handling methods (to be overridden by subclasses)
    function onSelect() as Lang.Boolean {
        return false; // Not handled by base component
    }

    function onBack() as Lang.Boolean {
        return false; // Not handled by base component
    }

    function onNextPage() as Lang.Boolean {
        return false; // Not handled by base component
    }

    function onPreviousPage() as Lang.Boolean {
        return false; // Not handled by base component
    }

    // Touch event handling (for touchscreen devices)
    function onTap(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        if (!_visible || !_enabled) {
            return false;
        }

        var coords = clickEvent.getCoordinates();
        if (containsPoint(coords[0], coords[1])) {
            return onSelect();
        }

        return false;
    }

    // Animation support (basic)
    private var _animationStartTime as Lang.Number?;
    private var _animationDuration as Lang.Number;
    private var _animationProgress as Lang.Float;

    function startAnimation(duration as Lang.Number) as Void {
        _animationStartTime = System.getTimer();
        _animationDuration = duration;
        _animationProgress = 0.0;
    }

    function updateAnimation() as Lang.Boolean {
        if (_animationStartTime == null) {
            return false;
        }

        var currentTime = System.getTimer();
        var elapsed = currentTime - _animationStartTime as Lang.Number;

        if (elapsed >= _animationDuration) {
            _animationProgress = 1.0;
            _animationStartTime = null;
            return false; // Animation complete
        }

        _animationProgress = elapsed.toFloat() / _animationDuration.toFloat();
        return true; // Animation continuing
    }

    function getAnimationProgress() as Lang.Float {
        return _animationProgress;
    }

    function isAnimating() as Lang.Boolean {
        return _animationStartTime != null;
    }
}

// Text component extending base component
class TextComponent extends BaseComponent {

    private var _text as Lang.String;
    private var _font as Graphics.FontReference;
    private var _justification as Lang.Number;

    function initialize(x as Lang.Number, y as Lang.Number, width as Lang.Number, height as Lang.Number, text as Lang.String) {
        BaseComponent.initialize(x, y, width, height);
        _text = text;
        _font = Graphics.FONT_MEDIUM;
        _justification = Graphics.TEXT_JUSTIFY_CENTER;
    }

    function setText(text as Lang.String) as Void {
        _text = text;
    }

    function getText() as Lang.String {
        return _text;
    }

    function setFont(font as Graphics.FontReference) as Void {
        _font = font;
    }

    function setJustification(justification as Lang.Number) as Void {
        _justification = justification;
    }

    protected function drawContent(dc as Graphics.Dc) as Void {
        if (_text != null && _text.length() > 0) {
            dc.setColor(getTextColor(), Graphics.COLOR_TRANSPARENT);

            var centerX = getX() + (getWidth() / 2);
            var centerY = getY() + (getHeight() / 2);

            dc.drawText(centerX, centerY, _font, _text, _justification | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}