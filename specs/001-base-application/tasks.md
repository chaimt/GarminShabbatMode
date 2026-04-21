# Tasks: Base Garmin ShabbatMode Application

**Input**: Design documents from `/specs/001-base-application/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), context.md

**Tests**: Tests are OPTIONAL - only including foundational test setup as no specific tests were requested.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Garmin project**: `src/`, `tests/`, `resources/` at repository root
- Paths assume standard Garmin Connect IQ application structure

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create project directory structure per implementation plan
- [x] T002 Initialize Garmin Connect IQ project with manifest.xml
- [x] T003 [P] Create src/models/ directory structure
- [x] T004 [P] Create src/services/ directory structure  
- [x] T005 [P] Create src/ui/ directory structure
- [x] T006 [P] Create src/lib/ directory structure with storage/, validation/, logging/ subdirectories
- [x] T007 [P] Create tests/ directory structure with unit/, integration/, ui/ subdirectories
- [x] T008 [P] Create resources/ directory structure with layouts/, strings/, images/ subdirectories

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T009 Create base Application model in src/models/Application.mc
- [x] T010 [P] Create storage utilities in src/lib/storage/StorageManager.mc
- [x] T011 [P] Create logging utilities in src/lib/logging/Logger.mc
- [x] T012 [P] Create validation utilities in src/lib/validation/Validator.mc
- [x] T013 Setup error handling framework in src/lib/ErrorHandler.mc
- [x] T014 Create base UI component framework in src/ui/components/BaseComponent.mc

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Core Application Setup (Priority: P1) 🎯 MVP

**Goal**: Application initializes, launches successfully, and displays main interface with no errors

**Independent Test**: Can be fully tested by launching the application and verifying it starts without errors and displays the main interface

### Implementation for User Story 1

- [x] T015 [P] [US1] Create Configuration model in src/models/Configuration.mc
- [x] T016 [US1] Implement ConfigService for configuration management in src/services/ConfigService.mc
- [x] T017 [US1] Create MainView for primary application interface in src/ui/MainView.mc
- [x] T018 [US1] Implement application lifecycle management in src/models/Application.mc
- [x] T019 [US1] Add application initialization logic with default configuration
- [x] T020 [US1] Add error handling for initialization failures
- [x] T021 [US1] Create basic UI layout definition in resources/layouts/main_layout.xml
- [x] T022 [P] [US1] Add application strings in resources/strings/strings.xml

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Basic Settings Management (Priority: P2)

**Goal**: Users can access settings screen, modify configuration values, and settings persist between app launches

**Independent Test**: Can be tested by accessing settings screen and modifying configuration values that persist between app launches

### Implementation for User Story 2

- [ ] T023 [US2] Create SettingsView for settings management interface in src/ui/SettingsView.mc
- [ ] T024 [P] [US2] Create settings UI components in src/ui/components/SettingsInput.mc
- [ ] T025 [P] [US2] Create settings UI components in src/ui/components/SettingsToggle.mc
- [ ] T026 [US2] Extend ConfigService to handle settings persistence in src/services/ConfigService.mc
- [ ] T027 [US2] Add settings validation logic to ConfigService
- [ ] T028 [US2] Implement navigation between MainView and SettingsView
- [ ] T029 [US2] Add settings screen layout in resources/layouts/settings_layout.xml
- [ ] T030 [P] [US2] Add settings-related strings in resources/strings/strings.xml

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Device Integration Foundation (Priority: P3)

**Goal**: Application can detect and query basic Garmin device functions and capabilities

**Independent Test**: Can be tested by verifying the app can query basic device information and status

### Implementation for User Story 3

- [ ] T031 [P] [US3] Create DeviceInterface model in src/models/DeviceInterface.mc
- [ ] T032 [US3] Implement DeviceService for device interaction in src/services/DeviceService.mc
- [ ] T033 [US3] Add device capability detection logic to DeviceService
- [ ] T034 [US3] Add device status querying functionality to DeviceService
- [ ] T035 [US3] Integrate device information display in MainView
- [ ] T036 [US3] Add error handling for device integration failures
- [ ] T037 [P] [US3] Add device-related strings in resources/strings/strings.xml

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T038 [P] Add comprehensive error logging across all components
- [ ] T039 [P] Add memory usage optimization for device constraints
- [ ] T040 [P] Add application icons in resources/images/
- [ ] T041 Performance optimization for launch time requirements
- [ ] T042 Add input validation across all user interfaces
- [ ] T043 Code cleanup and consistent coding standards

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Integrates with US1 components but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May display in US1 interface but independently testable

### Within Each User Story

- Models before services
- Services before UI components
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- UI components and string resources within each story can be developed in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch models and resources for User Story 1 together:
Task: "Create Configuration model in src/models/Configuration.mc"
Task: "Add application strings in resources/strings/strings.xml"
Task: "Create basic UI layout definition in resources/layouts/main_layout.xml"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently - app launches and displays interface
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Core Application Setup)
   - Developer B: User Story 2 (Basic Settings Management)
   - Developer C: User Story 3 (Device Integration Foundation)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Focus on Garmin Connect IQ best practices and memory efficiency
- Ensure compliance with <50MB memory constraint and <5s launch time