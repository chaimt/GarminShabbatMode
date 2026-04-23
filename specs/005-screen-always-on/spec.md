# Feature Specification: Always-On Screen While App Is Running

**Feature Branch**: `005-screen-always-on`  
**Created**: 2026-04-23  
**Status**: Draft  
**Input**: User description: "while app is Running disable the screen off"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Screen Stays On During Normal Mode (Priority: P1)

As a Shabbat observer using ShabbatMode outside of Shabbat (countdown mode), I want the watch screen to remain fully visible without going dark so that I can check the time without having to raise my wrist or press buttons.

**Why this priority**: Core of the feature — the screen going off defeats the purpose of the app. This is a direct implementation of Constitution Principle II.

**Independent Test**: Launch the app in the simulator. Wait longer than the default watch timeout (30 seconds). Verify the screen does not dim or turn off while the widget is in the foreground.

**Acceptance Scenarios**:

1. **Given** ShabbatMode is running in countdown mode, **When** no user interaction occurs for 30+ seconds, **Then** the screen remains fully lit and visible
2. **Given** ShabbatMode is running in countdown mode, **When** the keep-alive mechanism is active, **Then** `WatchUi.requestUpdate()` is called at a short enough interval to prevent the system from timing out the display

---

### User Story 2 - Screen Stays On During Shabbat Conservation Mode (Priority: P1)

As a Shabbat observer using ShabbatMode during Shabbat (conservation mode, 30-second refresh), I want the screen to remain always on even though display refreshes are reduced to once per 30 seconds, so that I can see the time at any moment without interaction.

**Why this priority**: Critical — conservation mode reduces refresh to 30s which would cause the screen to time out on most Garmin devices. Principle II requires always-on display during Shabbat.

**Independent Test**: Enable Shabbat mode or simulate it. Verify the refresh timer is at 30s but the screen remains on indefinitely. Verify that the keep-alive does not trigger a full expensive redraw (time/sun recalculation) — only a lightweight screen wake.

**Acceptance Scenarios**:

1. **Given** ShabbatMode is in Shabbat conservation mode (30s refresh), **When** no user interaction occurs for 30+ seconds, **Then** the screen remains fully lit and visible without going dark
2. **Given** the screen keep-alive fires between 30s refresh ticks, **When** `onUpdate()` is triggered by the keep-alive, **Then** the display is redrawn with the cached content (no new time/sun calculation), preserving battery conservation behavior
3. **Given** the keep-alive timer is running, **When** the app goes to the background (`onHide()`), **Then** the keep-alive timer stops to preserve battery while the app is not visible
4. **Given** the app returns to the foreground (`onShow()`), **When** the view becomes visible again, **Then** the keep-alive timer restarts immediately

---

### User Story 3 - Clean Integration with Existing Timer Architecture (Priority: P2)

As a developer maintaining ShabbatMode, I want the screen keep-alive to be implemented as a clean, independent service so that it does not couple with the display refresh logic or the battery conservation service.

**Why this priority**: Code quality — decoupling the keep-alive from the refresh timer makes the architecture easier to maintain and test.

**Independent Test**: Verify that `BatteryConservationService.getRefreshIntervalMs()` still returns 30000ms during Shabbat. Verify that the `DisplayService` keep-alive timer runs independently at its own interval. Verify that `MainView` correctly starts/stops both timers in `onShow()`/`onHide()`.

**Acceptance Scenarios**:

1. **Given** the `DisplayService` exists, **When** it is initialized, **Then** it encapsulates the keep-alive timer and interval as private state
2. **Given** conservation mode is active, **When** `DisplayService.keepAlive()` fires, **Then** it sets a `_isKeepAliveTick` flag and calls `WatchUi.requestUpdate()`
3. **Given** `onUpdate()` is called due to a keep-alive tick, **When** `_isKeepAliveTick` is true, **Then** `onUpdate()` redraws using cached display state without recalculating astronomical data
