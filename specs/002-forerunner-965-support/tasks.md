# Tasks: Forerunner 965 Device Support

**Input**: Design documents from `/specs/002-forerunner-965-support/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), context.md

**Dependencies**: This feature REQUIRES the base application (001-base-application) to be completed first.

**Tests**: Tests are OPTIONAL - including device-specific validation tests where appropriate.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Garmin project enhancement**: Extends existing `src/`, `tests/`, `resources/` structure
- Device-specific paths: `src/ui/fr965/`, `src/lib/device/`, `resources/layouts/fr965/`

---

## Phase 1: Setup (Forerunner 965 Infrastructure)

**Purpose**: Device-specific infrastructure and directory structure

**⚠️ PREREQUISITE**: Base application (001-base-application) must be fully implemented first

- [ ] T001 Create Forerunner 965-specific directory structure in src/ui/fr965/
- [ ] T002 [P] Create adaptive UI framework directory structure in src/ui/adaptive/
- [ ] T003 [P] Create device-specific utilities directory structure in src/lib/device/
- [ ] T004 [P] Create compatibility framework directory structure in src/lib/compatibility/
- [ ] T005 [P] Create Forerunner 965 resources structure in resources/layouts/fr965/
- [ ] T006 [P] Create Forerunner 965 images structure in resources/images/fr965/
- [ ] T007 Update manifest.xml to include Forerunner 965 device support

---

## Phase 2: Foundational (Device Detection Framework)

**Purpose**: Core device detection and profiling infrastructure that MUST be complete before device-specific features

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T008 Create base DeviceProfile model in src/models/DeviceProfile.mc
- [ ] T009 [P] Create HardwareCapabilities model in src/models/HardwareCapabilities.mc
- [ ] T010 Create DeviceDetectionService in src/services/DeviceDetectionService.mc
- [ ] T011 [P] Create DeviceRegistry for supported device tracking in src/lib/compatibility/DeviceRegistry.mc
- [ ] T012 [P] Create FallbackHandler for unsupported features in src/lib/compatibility/FallbackHandler.mc
- [ ] T013 Create CapabilityDetector utility in src/lib/device/CapabilityDetector.mc

**Checkpoint**: Device detection foundation ready - Forerunner 965-specific implementation can now begin

---

## Phase 3: User Story 1 - Device Recognition and Compatibility (Priority: P1) 🎯 MVP

**Goal**: Application correctly recognizes Forerunner 965 devices and loads appropriate configurations with no compatibility errors

**Independent Test**: Can be fully tested by installing the app on a Forerunner 965 and verifying device-specific configurations are loaded and no compatibility errors occur

### Implementation for User Story 1

- [ ] T014 [P] [US1] Create FR965Profile model in src/models/FR965Profile.mc
- [ ] T015 [P] [US1] Create FR965Utils device-specific utilities in src/lib/device/FR965Utils.mc
- [ ] T016 [US1] Implement Forerunner 965 detection logic in DeviceDetectionService
- [ ] T017 [US1] Add Forerunner 965 profile to DeviceRegistry
- [ ] T018 [US1] Create Forerunner 965 hardware capability definitions
- [ ] T019 [US1] Implement device-specific configuration loading
- [ ] T020 [US1] Add error handling for Forerunner 965 detection failures
- [ ] T021 [P] [US1] Create device-specific strings in resources/strings/fr965_strings.xml

**Checkpoint**: At this point, User Story 1 should be fully functional - app recognizes Forerunner 965 and loads proper configuration

---

## Phase 4: User Story 2 - Screen and UI Optimization (Priority: P2)

**Goal**: App interface is properly sized and optimized for Forerunner 965's 454x454 pixel screen with all UI elements clearly visible and properly aligned

**Independent Test**: Can be tested by navigating through all app screens on a Forerunner 965 and verifying proper layout, text readability, and button accessibility

### Implementation for User Story 2

- [ ] T022 [P] [US2] Create ScreenAdapter for resolution adaptation in src/ui/adaptive/ScreenAdapter.mc
- [ ] T023 [P] [US2] Create LayoutManager for dynamic layouts in src/ui/adaptive/LayoutManager.mc
- [ ] T024 [US2] Create UIOptimizationService in src/services/UIOptimizationService.mc
- [ ] T025 [P] [US2] Create FR965MainView optimized for device in src/ui/fr965/FR965MainView.mc
- [ ] T026 [P] [US2] Create FR965SettingsView optimized for device in src/ui/fr965/FR965SettingsView.mc
- [ ] T027 [P] [US2] Create FR965Components device-specific UI components in src/ui/fr965/FR965Components.mc
- [ ] T028 [US2] Integrate adaptive UI components with base application views
- [ ] T029 [P] [US2] Create Forerunner 965 main layout in resources/layouts/fr965/fr965_main_layout.xml
- [ ] T030 [P] [US2] Create Forerunner 965 settings layout in resources/layouts/fr965/fr965_settings_layout.xml
- [ ] T031 [P] [US2] Optimize icons for 454x454 resolution in resources/images/fr965/icons_454x454/

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - device recognized and UI properly optimized

---

## Phase 5: User Story 3 - Device-Specific Feature Integration (Priority: P3)

**Goal**: Application leverages Forerunner 965-specific capabilities and sensors, providing enhanced ShabbatMode features unique to the device

**Independent Test**: Can be tested by accessing device-specific features and verifying they work correctly with the Forerunner 965's sensors and capabilities

### Implementation for User Story 3

- [ ] T032 [US3] Create HardwareService for device integration in src/services/HardwareService.mc
- [ ] T033 [P] [US3] Create PerformanceProfiler for optimization in src/lib/device/PerformanceProfiler.mc
- [ ] T034 [US3] Implement Forerunner 965 sensor integration (GPS, heart rate, accelerometer)
- [ ] T035 [US3] Add touchscreen input handling optimized for device
- [ ] T036 [US3] Implement device-specific battery optimization features
- [ ] T037 [US3] Create enhanced ShabbatMode features utilizing device capabilities
- [ ] T038 [US3] Integrate device features with existing application functionality
- [ ] T039 [P] [US3] Add device-specific background images in resources/images/fr965/backgrounds/
- [ ] T040 [P] [US3] Create device-specific feature strings in resources/strings/fr965_strings.xml

**Checkpoint**: All user stories should now be independently functional - full Forerunner 965 support with enhanced features

---

## Phase 6: Polish & Cross-Device Compatibility

**Purpose**: Improvements that ensure robust device support and fallback behavior

- [ ] T041 [P] Add comprehensive device compatibility testing
- [ ] T042 [P] Implement graceful fallback for unsupported Forerunner 965 firmware versions
- [ ] T043 Performance optimization for Forerunner 965 memory constraints
- [ ] T044 [P] Add device-specific error logging and diagnostics
- [ ] T045 [P] Create device compatibility documentation
- [ ] T046 Validate integration with base application across all user scenarios
- [ ] T047 [P] Add Forerunner 965-specific unit tests in tests/device/

---

## Dependencies & Execution Order

### Phase Dependencies

- **CRITICAL PREREQUISITE**: Base application (001-base-application) must be fully completed first
- **Setup (Phase 1)**: No dependencies after base app - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May use US1 device detection but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Integrates with US1/US2 but independently testable

### Within Each User Story

- Models and utilities before services
- Services before UI components
- Core device integration before enhanced features
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- Device-specific resources (layouts, strings, images) can be developed in parallel within each story
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 2

```bash
# Launch UI components and resources for User Story 2 together:
Task: "Create ScreenAdapter for resolution adaptation in src/ui/adaptive/ScreenAdapter.mc"
Task: "Create LayoutManager for dynamic layouts in src/ui/adaptive/LayoutManager.mc"
Task: "Create FR965MainView optimized for device in src/ui/fr965/FR965MainView.mc"
Task: "Create Forerunner 965 main layout in resources/layouts/fr965/fr965_main_layout.xml"
Task: "Optimize icons for 454x454 resolution in resources/images/fr965/icons_454x454/"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (after base app completion)
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently - app recognizes Forerunner 965 device
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Device detection ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers (after base app completion):

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Device Recognition and Compatibility)
   - Developer B: User Story 2 (Screen and UI Optimization)
   - Developer C: User Story 3 (Device-Specific Feature Integration)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- **CRITICAL**: This feature cannot begin until base application is complete
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Focus on Forerunner 965 specifications: 454x454 pixels, touchscreen + 5 buttons
- Ensure compliance with <30MB memory constraint and <5s launch time on Forerunner 965
- Maintain compatibility and fallback behavior for unsupported features