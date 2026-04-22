# Feature Specification: Shabbat Time Display

**Feature Branch**: `003-shabbat-time-display`  
**Created**: 2026-04-13  
**Status**: Draft  
**Input**: User description: "app should display the following information: time, sunset, sunrise, time of candle lighting, time of end of shabbat"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Basic Time Display (Priority: P1)

As a user, I want to see the current time prominently displayed in the app so that I always know what time it is during Shabbat preparation and observance.

**Why this priority**: Foundation for all time-based functionality - users need to see current time as a baseline for all other calculations.

**Independent Test**: Can be fully tested by opening the app and verifying the current time is displayed accurately and updates correctly.

**Acceptance Scenarios**:

1. **Given** the app is open, **When** I view the main screen, **Then** the current time is prominently displayed in a clear, readable format
2. **Given** the app is running, **When** time passes, **Then** the displayed time updates automatically and accurately

---

### User Story 2 - Astronomical Time Calculations (Priority: P2)

As a user, I want to see sunrise and sunset times for my location so that I can plan my daily activities around the natural daylight cycle.

**Why this priority**: Essential for Shabbat observance planning - sunset timing is critical for determining when Shabbat begins and other calculations depend on it.

**Independent Test**: Can be tested by verifying displayed sunrise/sunset times match astronomical calculations for the user's current location and date.

**Acceptance Scenarios**:

1. **Given** my location is known, **When** I view the app, **Then** today's sunrise and sunset times are accurately displayed
2. **Given** the app has calculated astronomical times, **When** I check the times against astronomical sources, **Then** they match within acceptable accuracy (±2 minutes)

---

### User Story 3 - Shabbat Time Calculations (Priority: P3)

As a practicing Jewish user, I want to see the exact times for candle lighting and the end of Shabbat so that I can properly observe Shabbat according to halacha (Jewish law).

**Why this priority**: Core functionality for Shabbat observance - provides the specific religious times needed for proper Shabbat observance.

**Independent Test**: Can be tested by verifying candle lighting time (typically 18-20 minutes before sunset) and end of Shabbat time (typically 25-42 minutes after sunset) are calculated and displayed correctly.

**Acceptance Scenarios**:

1. **Given** sunset time is calculated, **When** I view the app on Friday, **Then** candle lighting time is displayed (typically 18-20 minutes before sunset)
2. **Given** sunset time is calculated, **When** I view the app on Saturday evening, **Then** end of Shabbat time is displayed (typically 25-42 minutes after sunset depending on location customs)

---

### User Story 4 - Shabbat Battery Conservation Mode (Priority: P2)

As a user on Shabbat (Saturday), I want the app to reduce its internal activity to preserve battery life so that the device lasts throughout the day without needing a charge.

**Why this priority**: On Shabbat, charging a device is not permitted, so the app must be mindful of battery consumption throughout the entire day.

**Independent Test**: Can be tested by verifying that during the Shabbat period the app reduces its screen refresh rate, GPS polling frequency, and background calculations compared to non-Shabbat operation, and that the system-level Do Not Disturb mode is **not** activated.

**Acceptance Scenarios**:

1. **Given** Shabbat has begun (after candle lighting time on Friday), **When** the app is running, **Then** it enters a low-activity mode — reducing screen update frequency, GPS polling, and background work — without activating the device's system-level Do Not Disturb feature
2. **Given** the app is in Shabbat battery conservation mode, **When** Shabbat ends (after end-of-Shabbat time on Saturday night), **Then** the app automatically returns to normal activity levels
3. **Given** the app is in Shabbat battery conservation mode, **When** I view the screen, **Then** the display shows a minimal, static-like layout (similar in spirit to a Do Not Disturb screen) that refreshes infrequently to minimize power draw, with the label reading "Shabbat"

---

### Edge Cases

- What happens when location services are unavailable or denied?
- How does the system handle timezone changes or travel?
- What occurs when astronomical calculations fail due to extreme latitudes (polar regions)?
- How does the app handle date transitions and time zone changes?
- How does the app detect Shabbat start/end reliably enough to enter and exit battery conservation mode?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display current time with second-level accuracy
- **FR-002**: System MUST calculate sunrise time based on user's current location
- **FR-003**: System MUST calculate sunset time based on user's current location  
- **FR-004**: System MUST calculate candle lighting time (configurable minutes before sunset, default 18 minutes)
- **FR-005**: System MUST calculate end of Shabbat time (configurable minutes after sunset, default 25-42 minutes)
- **FR-006**: System MUST handle timezone changes and daylight saving time transitions
- **FR-007**: System MUST provide fallback behavior when location services are unavailable
- **FR-008**: System MUST update time displays automatically without user intervention
- **FR-009**: System MUST enter a battery conservation mode during the Shabbat period (from candle lighting time Friday through end-of-Shabbat Saturday night) that reduces screen refresh rate, GPS polling frequency, and background calculations
- **FR-010**: System MUST NOT activate the device's system-level Do Not Disturb mode; battery conservation is achieved purely through internal app-level activity reduction
- **FR-011**: System MUST automatically exit battery conservation mode when the Shabbat period ends and return to normal operational activity levels
- **FR-012**: System MUST display a simplified, low-refresh-rate layout during battery conservation mode, visually inspired by a minimal Do Not Disturb style screen
- **FR-013**: System MUST display "Shabbat" as the mode label at all times (both during normal operation and battery conservation mode)

### Key Entities *(include if feature involves data)*

- **TimeInfo**: Current time with timezone information
- **Location**: User's geographic coordinates for calculations
- **AstronomicalData**: Sunrise and sunset calculations
- **ShabbatTimes**: Candle lighting and end of Shabbat calculations
- **TimeConfiguration**: User preferences for time offsets and display formats

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Time displays update within 1 second of actual time changes
- **SC-002**: Astronomical calculations are accurate to within ±2 minutes of authoritative sources
- **SC-003**: App continues to function with cached location data when GPS is unavailable for up to 24 hours
- **SC-004**: All time calculations complete within 500ms of location acquisition
- **SC-005**: During Shabbat battery conservation mode, screen refresh rate is reduced by at least 80% compared to normal operation
- **SC-006**: During Shabbat battery conservation mode, GPS polling frequency is reduced to at most once every 30 minutes (or disabled entirely if location is already cached)
- **SC-007**: The device's system-level Do Not Disturb mode remains unchanged (neither enabled nor disabled) when the app enters or exits battery conservation mode

## Assumptions

- Device has access to location services (GPS or network-based)
- User is in a location where sunrise/sunset can be calculated (not extreme polar regions)
- Device has accurate system time and timezone settings
- User follows standard timing customs (18-20 min before sunset for candles, 25-42 min after for Shabbat end)
- Base ShabbatMode application framework is already implemented
- Internet connectivity available for initial astronomical calculation library setup
- Battery conservation mode is implemented entirely at the app level; no system-level Do Not Disturb or power-saving modes are activated — the visual and behavioral pattern is inspired by Do Not Disturb but is a custom, app-internal implementation
- Shabbat period boundaries (start/end) are derived from the already-calculated candle lighting and end-of-Shabbat times (FR-004, FR-005)