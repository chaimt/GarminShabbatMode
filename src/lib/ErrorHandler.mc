using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Application;

class ErrorHandler {

    private var _logger as Logger?;
    private var _storageManager as StorageManager?;

    function initialize() {
        _logger = new Logger();
        _storageManager = new StorageManager();
    }

    function handleError(context as String, ex as Exception) as Void {
        try {
            // Log the error details
            var errorMessage = Lang.format("Error in $1$: $2$", [context, ex.getErrorMessage()]);

            if (_logger != null) {
                _logger.error(errorMessage);
            } else {
                System.println("ERROR: " + errorMessage);
            }

            // Store error for debugging if storage is available
            if (_storageManager != null) {
                var errorData = {
                    "timestamp" => Time.now().value(),
                    "context" => context,
                    "message" => ex.getErrorMessage(),
                    "type" => "exception"
                };

                _storageManager.setValue("last_error", errorData);
            }

            // Show user-friendly error message
            showUserError(context, ex);

        } catch (handlerEx instanceof Exception) {
            // Fallback error handling if the error handler itself fails
            System.println("CRITICAL: Error handler failed: " + handlerEx.getErrorMessage());
            showCriticalError();
        }
    }

    function handleValidationError(context as String, validationResult as Number) as Void {
        var errorMessage = Lang.format("Validation error in $1$: $2$", [
            context,
            Validator.getValidationErrorMessage(validationResult)
        ]);

        if (_logger != null) {
            _logger.warn(errorMessage);
        } else {
            System.println("WARNING: " + errorMessage);
        }

        // Show validation error to user
        showValidationError(context, validationResult);
    }

    function handleStorageError(operation as String, key as String) as Void {
        var errorMessage = Lang.format("Storage error during $1$ for key: $2$", [operation, key]);

        if (_logger != null) {
            _logger.error(errorMessage);
        } else {
            System.println("ERROR: " + errorMessage);
        }

        // Storage errors are usually not shown to users unless critical
    }

    function handleLocationError(context as String) as Void {
        var errorMessage = Lang.format("Location error in $1$", [context]);

        if (_logger != null) {
            _logger.warn(errorMessage);
        } else {
            System.println("WARNING: " + errorMessage);
        }

        showLocationError();
    }

    function handleTimeCalculationError(calculationType as String) as Void {
        var errorMessage = Lang.format("Time calculation error: $1$", [calculationType]);

        if (_logger != null) {
            _logger.error(errorMessage);
        } else {
            System.println("ERROR: " + errorMessage);
        }

        showTimeCalculationError(calculationType);
    }

    private function showUserError(context as String, ex as Exception) as Void {
        var message = "An error occurred. Please try again.";

        // Customize message based on context
        if (context.find("init") != null) {
            message = "Failed to initialize application. Please restart.";
        } else if (context.find("storage") != null) {
            message = "Failed to save settings. Changes may not persist.";
        } else if (context.find("location") != null) {
            message = "Location services unavailable. Some features may not work.";
        }

        // Show a simple alert to the user
        showAlert("Error", message);
    }

    private function showValidationError(context as String, validationResult as Number) as Void {
        var message = "Invalid input. Please check your entries.";
        showAlert("Invalid Input", message);
    }

    private function showLocationError() as Void {
        var message = "Location services are required for time calculations. Please enable location access.";
        showAlert("Location Required", message);
    }

    private function showTimeCalculationError(calculationType as String) as Void {
        var message = Lang.format("Unable to calculate $1$. Please check your location settings.", [calculationType]);
        showAlert("Calculation Error", message);
    }

    private function showCriticalError() as Void {
        var message = "A critical error occurred. Please restart the application.";
        showAlert("Critical Error", message);
    }

    private function showAlert(title as String, message as String) as Void {
        try {
            // Create and show a simple confirmation dialog
            var dialog = new WatchUi.Confirmation(message);
            WatchUi.pushView(dialog, new ConfirmationDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } catch (ex instanceof Exception) {
            // If UI fails, at least print to console
            System.println(title + ": " + message);
        }
    }

    // Helper method to get the last error for debugging
    function getLastError() as Dictionary<String, Object>? {
        if (_storageManager != null) {
            var errorData = _storageManager.getValue("last_error");
            if (errorData instanceof Dictionary) {
                return errorData as Dictionary<String, Object>;
            }
        }
        return null;
    }

    function clearLastError() as Boolean {
        if (_storageManager != null) {
            return _storageManager.deleteValue("last_error");
        }
        return false;
    }
}

class ConfirmationDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}