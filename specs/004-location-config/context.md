# Feature Context

**Feature**: Manual Location Configuration
**Mission**: Allow users to manually configure latitude and longitude coordinates for astronomical calculations, with a toggle between GPS and manual location source
**Code Paths**: src/models/TimeConfiguration.mc, src/services/LocationService.mc, src/services/ConfigService.mc, src/ui/TimeSettingsView.mc, src/ui/TimeDisplayView.mc, src/lib/validation/LocationValidator.mc

## Technical Context

**Language**: Monkey C (Connect IQ SDK 4.0+)
**Key APIs**: Toybox.WatchUi (NumberPicker, Menu2), Toybox.Application.Storage
**Permissions Required**: Positioning (already in manifest — reduced use when manual mode active)
**Dependencies**: Feature 003 (shabbat-time-display) must be complete; extends its LocationService, ConfigService, and settings UI

## Personas

- Orthodox/Conservative Jewish user who lives in a fixed location and prefers reliable manual coordinates over GPS
- Traveler who wants to pre-configure a destination location before arrival
- User in a GPS-poor environment (e.g., indoors or underground) needing fallback manual coordinates

## Constraints

- Monkey C does not provide a text-input widget; coordinate entry must use WatchUi.NumberPicker or Menu2 controls
- Manual coordinates stored as Float in Application.Storage (keys: `locationSource`, `manualLatitude`, `manualLongitude`)
- Latitude ∈ [−90, 90], longitude ∈ [−180, 180]; polar region warning at |lat| > 66.5°
- Switching location source must not require app restart
- Manual mode must suppress GPS polling completely (no Positioning events)

## Key Technical Challenges

- Implementing numeric coordinate input within Monkey C's limited UI toolkit
- Ensuring LocationService correctly branches between GPS and manual paths without duplicating location resolution logic
- Validating and displaying error state when manual source is selected but no coordinates are configured
