# Tasks: Shabbat Time Display

**Input**: Design documents from `/specs/003-shabbat-time-display/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), context.md

**Dependencies**: This feature REQUIRES the base application framework to be completed first.

**Tests**: Tests are OPTIONAL - including timing accuracy and calculation validation tests where appropriate.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Garmin project enhancement**: Extends existing `src/`, `resources/` structure
- Time-specific paths: `src/services/`, `src/lib/calculations/`, `src/ui/components/`

---

## Phase 1: Setup (Time Display Infrastructure)

**Purpose**: Core infrastructure for time-related functionality

**⚠️ PREREQUISITE**: Base application framework must be implemented first

- [x] T001 Create time display directory structure in src/ui/components/
- [x] T002 [P] Create calculations utilities directory structure in src/lib/calculations/
- [x] T003 [P] Create formatters directory structure in src/lib/formatters/
- [x] T004 [P] Create validators directory structure in src/lib/validators/
- [x] T005 [P] Create cache directory structure in src/cache/
- [x] T006 [P] Create time-specific resources in resources/layouts/ and resources/strings/
- [x] T007 [P] Create time-related icons directory in resources/images/time/
- [x] T008 Update manifest.xml to include location permissions for astronomical calculations

---

## Phase 2: Foundational (Time Services Framework)

**Purpose**: Core time management and location services that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T009 Create base TimeInfo model in src/models/TimeInfo.mc
- [ ] T010 [P] Create Location model in src/models/Location.mc
- [ ] T011 [P] Create TimeConfiguration model in src/models/TimeConfiguration.mc
- [ ] T012 Create TimeService for real-time clock management in src/services/TimeService.mc
- [ ] T013 [P] Create LocationService for GPS and location acquisition in src/services/LocationService.mc
- [ ] T014 [P] Create TimezoneService for timezone handling in src/services/TimezoneService.mc
- [ ] T015 [P] Create LocationCache for cached location data in src/cache/LocationCache.mc
- [ ] T016 [P] Create TimeFormatter for time string formatting in src/lib/formatters/TimeFormatter.mc
- [ ] T017 [P] Create LocationValidator for GPS coordinate validation in src/lib/validators/LocationValidator.mc

**Checkpoint**: Time and location foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Basic Time Display (Priority: P1) 🎯 MVP

**Goal**: Display current time prominently with automatic real-time updates

**Independent Test**: Can be fully tested by opening the app and verifying the current time is displayed accurately and updates correctly

### Implementation for User Story 1

- [ ] T018 [P] [US1] Create ClockComponent for current time display in src/ui/components/ClockComponent.mc
- [ ] T019 [US1] Create TimeDisplayView for main time interface in src/ui/TimeDisplayView.mc
- [ ] T020 [US1] Implement real-time update mechanism in TimeService
- [ ] T021 [US1] Add time display formatting and localization support
- [ ] T022 [US1] Integrate ClockComponent with main application interface
- [ ] T023 [US1] Add automatic time update scheduling (1-second intervals)
- [ ] T024 [P] [US1] Create time display layout in resources/layouts/time_display_layout.xml
- [ ] T025 [P] [US1] Add time-related strings in resources/strings/time_strings.xml
- [ ] T026 [P] [US1] Add clock icons in resources/images/time/clock_icons/

**Checkpoint**: At this point, User Story 1 should be fully functional - app displays current time with real-time updates

---

## Phase 4: User Story 2 - Astronomical Time Calculations (Priority: P2)

**Goal**: Calculate and display accurate sunrise and sunset times based on user's location

**Independent Test**: Can be tested by verifying displayed sunrise/sunset times match astronomical calculations for the user's current location and date

### Implementation for User Story 2

- [ ] T027 [P] [US2] Create AstronomicalData model in src/models/AstronomicalData.mc
- [ ] T028 [US2] Create AstronomicalService for sunrise/sunset calculations in src/services/AstronomicalService.mc
- [ ] T029 [P] [US2] Create SunPosition calculation algorithms in src/lib/calculations/SunPosition.mc
- [ ] T030 [P] [US2] Create DateMath utilities for date/time operations in src/lib/calculations/DateMath.mc
- [ ] T031 [P] [US2] Create SunTimesComponent for sunrise/sunset display in src/ui/components/SunTimesComponent.mc
- [ ] T032 [US2] Integrate location services with astronomical calculations
- [ ] T033 [US2] Add calculation caching for daily astronomical data in src/cache/CalculationCache.mc
- [ ] T034 [US2] Implement error handling for calculation failures and extreme latitudes
- [ ] T035 [US2] Add sunrise/sunset display to main time interface
- [ ] T036 [P] [US2] Add sun-related icons in resources/images/time/sun_icons/
- [ ] T037 [P] [US2] Add astronomical time strings in resources/strings/time_strings.xml

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - current time and astronomical times displayed

---

## Phase 5: User Story 3 - Shabbat Time Calculations (Priority: P3)

**Goal**: Calculate and display candle lighting and end of Shabbat times according to halacha (Jewish law)

**Independent Test**: Can be tested by verifying candle lighting time (18-20 minutes before sunset) and end of Shabbat time (25-42 minutes after sunset) are calculated and displayed correctly

### Implementation for User Story 3

- [ ] T038 [P] [US3] Create ShabbatTimes model in src/models/ShabbatTimes.mc
- [ ] T039 [US3] Create ShabbatTimeService for Shabbat-specific calculations in src/services/ShabbatTimeService.mc
- [ ] T040 [P] [US3] Create ShabbatTimesComponent for candle lighting and end times display in src/ui/components/ShabbatTimesComponent.mc
- [ ] T041 [US3] Implement configurable time offsets for candle lighting (default 18 minutes before sunset)
- [ ] T042 [US3] Implement configurable time offsets for end of Shabbat (default 25-42 minutes after sunset)
- [ ] T043 [US3] Add Shabbat time calculations based on sunset times
- [ ] T044 [US3] Create time configuration interface in TimeSettingsView
- [ ] T045 [US3] Integrate Shabbat times with main time display interface
- [ ] T046 [US3] Add validation for Shabbat time accuracy and edge cases
- [ ] T047 [P] [US3] Create time settings layout in resources/layouts/time_settings_layout.xml
- [ ] T048 [P] [US3] Add Shabbat-related strings in resources/strings/shabbat_strings.xml
- [ ] T049 [P] [US3] Add Shabbat icons (candles, etc.) in resources/images/time/shabbat_icons/

**Checkpoint**: All user stories should now be independently functional - complete time display with current, astronomical, and Shabbat times

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that enhance reliability and user experience across all time functionality

- [ ] T050 [P] Add comprehensive error handling for location service failures
- [ ] T051 [P] Implement battery-efficient GPS usage patterns
- [ ] T052 Performance optimization for time calculations and display updates
- [ ] T053 [P] Add timezone change detection and automatic recalculation
- [ ] T054 [P] Create fallback behavior for extreme latitudes and calculation edge cases
- [ ] T055 [P] Add accuracy validation tests comparing calculations to authoritative sources
- [ ] T056 Add user feedback for calculation accuracy and location status
- [ ] T057 [P] Create comprehensive time calculation documentation
- [ ] T058 [P] Add time calculation unit tests in tests/calculations/

---

## Dependencies & Execution Order

### Phase Dependencies

- **CRITICAL PREREQUISITE**: Base application framework must be fully completed first
- **Setup (Phase 1)**: No dependencies after base app - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Independent but provides data for US3
- **User Story 3 (P3)**: Depends on US2 sunset calculations but can be tested independently with mock data

### Within Each User Story

- Models before services that use them
- Calculation utilities before services that call them
- Services before UI components that display their data
- Core functionality before integration with main interface
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, US1 and US2 can start in parallel
- Resources (layouts, strings, icons) can be developed in parallel within each story
- Calculation utilities and validators can be developed in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 2

```bash
# Launch calculation components and resources for User Story 2 together:
Task: "Create SunPosition calculation algorithms in src/lib/calculations/SunPosition.mc"
Task: "Create DateMath utilities for date/time operations in src/lib/calculations/DateMath.mc"
Task: "Create SunTimesComponent for sunrise/sunset display in src/ui/components/SunTimesComponent.mc"
Task: "Add sun-related icons in resources/images/time/sun_icons/"
Task: "Add astronomical time strings in resources/strings/time_strings.xml"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (after base app completion)
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently - app displays current time with real-time updates
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Time services ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers (after base app completion):

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Basic Time Display)
   - Developer B: User Story 2 (Astronomical Time Calculations)
   - Developer C: User Story 3 (Shabbat Time Calculations) - starts after US2 provides sunset calculations
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- **CRITICAL**: This feature cannot begin until base application framework is complete
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Focus on accuracy requirements: ±2 minutes for astronomical calculations
- Ensure performance requirements: <500ms calculations, <1s display updates
- Handle edge cases: extreme latitudes, location unavailable, timezone changes
- Maintain battery efficiency in GPS usage and real-time updates