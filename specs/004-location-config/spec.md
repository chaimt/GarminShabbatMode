# Feature Specification: Manual Location Configuration

**Feature Branch**: `004-location-config`  
**Created**: 2026-04-22  
**Status**: Draft  
**Input**: User description: "add option to configure longitude and latitudes for calculations"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Manual Location Entry in Settings (Priority: P1)

As a user who travels or whose GPS is unreliable, I want to manually enter a latitude and longitude in the settings screen so that astronomical calculations use my specified location instead of relying on GPS.

**Why this priority**: Core feature — without this, the whole feature has no value. All other stories depend on the configured location being persisted and usable.

**Independent Test**: Open the settings view, enter a known lat/lon (e.g., New York: 40.6892°N, 74.0445°W), save, and verify the location is persisted to `Application.Storage`. Verify `TimeDisplayView` shows sunrise/sunset times consistent with New York at today's date (cross-check against a reference astronomical calculator).

**Acceptance Scenarios**:

1. **Given** I open the settings screen, **When** I navigate to the Location section, **Then** I see input fields for latitude and longitude with their current values
2. **Given** I enter a valid latitude (e.g., 40.6892) and longitude (e.g., -74.0445), **When** I save the settings, **Then** the values are persisted to `Application.Storage` and used for all subsequent astronomical calculations
3. **Given** I enter an out-of-range latitude (> 90 or < -90) or longitude (> 180 or < -180), **When** I attempt to save, **Then** an error message is shown and the invalid values are not saved

---

### User Story 2 - Location Source Toggle (GPS vs Manual) (Priority: P1)

As a user, I want to choose whether the app acquires my location automatically via GPS or uses a manually entered coordinate, so that I have full control over the location used for calculations.

**Why this priority**: Without this toggle, there is no way for the user to intentionally switch between GPS and manual mode — both stories are P1 as they form the MVP together.

**Independent Test**: Set location source to "Manual" with known coordinates, verify GPS polling stops and the manually stored lat/lon is used. Set back to "GPS", verify GPS polling resumes and the device-acquired location is used.

**Acceptance Scenarios**:

1. **Given** I open the settings screen, **When** I view the Location section, **Then** I see a toggle or picker to choose "GPS" or "Manual" as the location source
2. **Given** location source is set to "Manual", **When** the app calculates astronomical times, **Then** it uses the manually configured coordinates and does NOT initiate a GPS fix
3. **Given** location source is set to "GPS", **When** the app calculates astronomical times, **Then** it uses the GPS-acquired (or cached) coordinates as before, ignoring any manually configured values
4. **Given** location source is "Manual" and no manual coordinates have been entered, **When** the app attempts to calculate times, **Then** it displays a prompt to enter coordinates rather than showing erroneous times

---

### User Story 3 - Location Display on Main View (Priority: P2)

As a user, I want to see a brief location indicator on the main screen showing whether I am using GPS or a manually configured location, so that I always know which source is driving the calculations.

**Why this priority**: Enhances transparency; non-blocking for P1 stories but important for user trust.

**Independent Test**: With location source = "Manual" and custom coordinates saved, verify main view shows "Manual" (or the city/coordinate summary). Switch to GPS and verify indicator changes to "GPS" or "GPS: acquiring…".

**Acceptance Scenarios**:

1. **Given** location source is "GPS", **When** I view the main screen, **Then** the existing GPS status indicator ("GPS: acquiring…" or nothing once locked) continues to function as before
2. **Given** location source is "Manual", **When** I view the main screen, **Then** a compact location indicator shows "Manual" alongside or replacing the GPS status label
3. **Given** location source is "Manual" and coordinates are invalid or missing, **When** I view the main screen, **Then** the indicator shows "No location set" and times display "--"

---

---

### User Story 4 - GPS Location Capture to Manual Config (Priority: P1)

As a user, I want to press a single button in settings to capture my current GPS location and save it as my manual coordinates, so that I can set an accurate location without manually entering degrees.

**Why this priority**: Removes friction from manual coordinate setup — the main barrier to adoption of manual mode.

**Independent Test**: In the simulator with a simulated GPS fix, navigate to Settings → "Capture GPS" → SELECT. Verify: (a) row label changes to "Acquiring…", (b) after the fix callback fires, row shows "GPS Saved!", (c) source switches to "Manual", (d) lat/lon rows update to the captured values, (e) values persist after app restart.

**Acceptance Scenarios**:

1. **Given** I am in GPS mode and select "Capture GPS", **When** a fix is acquired, **Then** the coordinates are saved as my manual location, source switches to "manual", and the status shows "GPS Saved!"
2. **Given** GPS is unavailable or returns an invalid fix, **When** acquisition times out, **Then** the row shows "GPS failed" and source/coordinates are unchanged

---

### User Story 5 - GPS Coordinates Visible in Settings (Priority: P2)

As a user in GPS mode, I want to see the actual GPS coordinates currently in use on the settings screen, so that I know which location is driving the calculations before deciding whether to switch to manual mode.

**Why this priority**: Transparency — users need to verify GPS accuracy before committing to manual mode.

**Independent Test**: With a cached GPS fix and source = "GPS", open Settings. Verify lat/lon rows show the cached coordinates (e.g. 40°, -74°) rather than "0°". Pressing SELECT on these rows has no effect (read-only).

**Acceptance Scenarios**:

1. **Given** source is "GPS" and a cached fix exists, **When** I view the settings Location section, **Then** the lat/lon rows show the cached GPS coordinates, dimmed to indicate read-only
2. **Given** source is "GPS" but no cached fix exists, **When** I view the settings Location section, **Then** the lat/lon rows show "--"

---

### User Story 6 - System Last-Known Location on Launch (Priority: P1)

As a user, I want the app to immediately use the last-known GPS location from the system when it launches, so that astronomical calculations are available from the very first screen without a visible "acquiring" state.

**Why this priority**: Critical UX — users should see times immediately, not a spinner, especially on Shabbat when they cannot interact with the device.

**Independent Test**: Launch the app immediately after a prior session that had a GPS fix. Verify `LocationService.hasLocation()` is true before the first timer tick fires and Row 2 (sunrise/sunset) shows real times instead of "--".

**Acceptance Scenarios**:

1. **Given** the device has a system-cached GPS position from a prior session, **When** the app launches in GPS mode, **Then** location is available immediately from `LocationService` without waiting for a fresh GPS acquisition
2. **Given** source is "manual", **When** the app launches, **Then** the system last-known location is ignored and manual coordinates are used

---

### Edge Cases

- What happens if the user switches from Manual to GPS and no GPS fix is available? Use LocationCache (24h) as fallback per SC-003.
- What if the user enters polar-region coordinates (|lat| > 66.5°)? `LocationValidator.isPolarRegion()` triggers; display a warning and show "--" for calculated times.
- What if the user never configures manual coordinates but source is "Manual"? Show "--" for all calculated times and prompt user to enter coordinates.
- How are manual coordinates validated before save? Range check (lat ∈ [−90, 90], lon ∈ [−180, 180]) with decimal precision up to 4 decimal places.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a settings UI entry for manual latitude and longitude input
- **FR-002**: System MUST validate latitude ∈ [−90, 90] and longitude ∈ [−180, 180] before saving; reject invalid values with an error message
- **FR-003**: System MUST persist manual coordinates to `Application.Storage` via `ConfigService`
- **FR-004**: System MUST provide a user-selectable location source: `"gps"` (default) or `"manual"`
- **FR-005**: System MUST use manually configured coordinates for all astronomical calculations when source is `"manual"`
- **FR-006**: System MUST NOT initiate GPS polling when location source is `"manual"`
- **FR-007**: System MUST resume normal GPS polling behavior when source is switched back to `"gps"`
- **FR-008**: System MUST display a location source indicator on the main view that distinguishes GPS from manual mode
- **FR-009**: System MUST warn the user when manually entered coordinates fall within a polar region (|lat| > 66.5°)
- **FR-010**: System MUST show "--" for all astronomical times when location source is "manual" and no valid coordinates have been configured
- **FR-011**: System MUST provide a "Capture GPS" action in the settings that fires a `LOCATION_ONE_SHOT` acquisition, persists the resulting coordinates as the manual location, and switches source to "manual"; the action row MUST display live acquisition status ("Acquiring…" / "GPS Saved!" / "GPS failed")
- **FR-012**: System MUST call `Position.getInfo()` synchronously at app launch (when source is "gps") to seed `LocationService` with the OS-cached last-known position, enabling instant location availability before any timer fires

### Key Entities *(include if feature involves data)*

- **LocationConfiguration**: New sub-model (or extension of `TimeConfiguration`) holding `locationSource` (`"gps"` | `"manual"`), `manualLatitude` (`Float`), `manualLongitude` (`Float`)
- **LocationService**: Extended to check `locationSource` and return manual coordinates instead of GPS when appropriate
- **TimeSettingsView**: Extended with a Location section (source picker + lat/lon input fields)
- **TimeDisplayView**: Extended with a compact location source indicator

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Manual coordinates are persisted and survive an app restart; verified by closing and reopening the app
- **SC-002**: Astronomical times calculated from manually entered New York coordinates (40.6892, −74.0445) match reference values within ±2 minutes (per existing SC-002 accuracy requirement)
- **SC-003**: Switching to Manual mode stops GPS polling within one timer cycle (≤ 1 second)
- **SC-004**: Entering out-of-range coordinates shows a validation error within 100ms of the save attempt
- **SC-005**: Polar-region coordinates (e.g., lat = 70.0) trigger a warning and "--" display without crashing

## Assumptions

- The existing `TimeSettingsView` and `ConfigService` infrastructure will be extended, not replaced
- Monkey C does not provide a text-input widget; latitude and longitude input uses degree-by-degree increment/wrap via SELECT — no decimal precision picker
- `LocationValidator`, `TimeConfiguration`, and `Configuration` are all extended with new methods; feature 003 source files are modified, not just `LocationService`
- Manual coordinates are stored in `Application.Storage` using keys `"latitude"`, `"longitude"`, `"location_auto"` (canonical `Configuration.mc` keys) with `"manual_latitude"`/`"manual_longitude"` written as aliases for backward compatibility
- GPS fallback (LocationCache, 24h) remains unchanged when source = "gps"; system last-known (via `Position.getInfo()`) is additionally seeded at app launch
