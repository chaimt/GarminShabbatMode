---
description: "Task list for always-on screen feature"
---

# Tasks: Always-On Screen While App Is Running

**Input**: Design documents from `/specs/005-screen-always-on/`  
**Prerequisites**: plan.md ✅, spec.md ✅, context.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [SYNC/ASYNC] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[SYNC]**: Requires human review (complex logic, architectural decisions)
- **[ASYNC]**: Can be delegated (well-defined, clear specs)
- **[Story]**: Which user story (US1, US2, US3)

---

## Phase 1: Setup

**Purpose**: Create the new `DisplayService` file and prepare `MainView` for changes.

- [ ] T001 [ASYNC] Create `src/services/DisplayService.mc` with class skeleton (empty `initialize`, `start`, `stop`, `isRunning` stubs) — establishes the file so T002 and T003 can build on it

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement `DisplayService` fully before wiring it into `MainView`.

- [ ] T002 [SYNC] Implement `DisplayService` in `src/services/DisplayService.mc` — add `KEEP_ALIVE_INTERVAL_MS = 5000` constant; `_timer as Timer.Timer?`; `_isRunning as Lang.Boolean`; `_callback as Lang.Method?`; `initialize(callback as Lang.Method)` stores callback; `start()` creates/starts timer calling `_onTick()` at 5s repeat; `stop()` stops and nulls timer; `isRunning()` returns `_isRunning`; `_onTick()` private method invokes `_callback.invoke([])`; full null-safe guards throughout

---

## Phase 3: User Story 1 — Screen Stays On in Normal Mode

**Goal**: Screen never goes dark in countdown mode.

**Independent Test**: Launch app, wait 60s without interaction — screen stays on.

### Implementation for User Story 1

- [ ] T003 [SYNC] [US1] Add `_displayService as DisplayService?` and `_isKeepAliveTick as Lang.Boolean` fields to `MainView` in `src/ui/MainView.mc` — declare in `initialize()`, set `_isKeepAliveTick = false`, instantiate `_displayService = new DisplayService(method(:onKeepAlive))`; add public `onKeepAlive()` method that sets `_isKeepAliveTick = true` and calls `WatchUi.requestUpdate()`; wrap in try/catch
- [ ] T004 [SYNC] [US1] Start/stop `_displayService` in `onShow()`/`onHide()` in `src/ui/MainView.mc` — in `onShow()` call `_displayService.start()` after the existing `_updateTimer.start(...)` call; in `onHide()` call `_displayService.stop()` after the existing `_updateTimer.stop()` call; null-check before each call

**Checkpoint**: US1 complete — in normal countdown mode the 5s keep-alive fires and `onUpdate()` is called, preventing screen sleep.

---

## Phase 4: User Story 2 — Screen Stays On in Conservation Mode

**Goal**: Screen never sleeps during Shabbat even with 30s refresh interval.

**Independent Test**: Simulate Shabbat/conservation mode. Confirm `_updateTimer` ticks at 30s, `_displayService` ticks at 5s, and screen stays on between 30s refreshes.

### Implementation for User Story 2

- [ ] T005 [SYNC] [US2] Add keep-alive fast path to `onUpdate()` in `src/ui/MainView.mc` — at the very start of `onUpdate()`, read and reset `_isKeepAliveTick`; if it was `true` (keep-alive tick), determine the current display mode from `_conservationService` and `_shabbatService` exactly as the existing branch logic does, call the appropriate `update*Display()` helper and then `for`-loop to draw all components, then `return` immediately (skip the first-run overlay and error-screen calls, as those are only needed on real ticks); if `_isKeepAliveTick` was `false`, run the existing full path unchanged

**Checkpoint**: US2 complete — during Shabbat conservation mode the screen stays on via 5s keep-alive ticks; the 30s content refresh still controls actual time/end-of-Shabbat updates.

---

## Phase 5: User Story 3 — Clean Integration with Existing Architecture

**Goal**: `DisplayService` is decoupled and `BatteryConservationService` is unchanged.

**Independent Test**: Read `BatteryConservationService.getRefreshIntervalMs()` — must still return 30000ms in conservation mode. Verify `_displayService` has its own `_timer` instance. Verify no cross-references between `DisplayService` and `BatteryConservationService`.

### Implementation for User Story 3

- [ ] T006 [P] [ASYNC] [US3] Verify `BatteryConservationService.mc` requires no changes — confirm `getRefreshIntervalMs()` is unchanged and `DisplayService` is not imported or referenced; document in a code comment on `DisplayService` that it is intentionally independent of `BatteryConservationService`
- [ ] T007 [P] [ASYNC] [US3] Add `DisplayService` to `src/services/` imports — ensure the barrel file or any required `using` statements reference `DisplayService` so it compiles; verify `MainView.mc` uses `using Toybox.Timer` (already present) and no extra barrel entries are needed for Monkey C class resolution

**Checkpoint**: US3 complete — architecture is clean; `DisplayService` is a standalone service wired only into `MainView`.

---

## Phase 6: Polish & Validation

- [ ] T008 [ASYNC] Build the project and resolve any compile errors — run `task build` (or the equivalent Taskfile target) from repo root; fix any type errors or missing `using` declarations introduced by `DisplayService` or `MainView` changes
- [ ] T009 [ASYNC] Smoke test in Connect IQ Simulator — launch widget, observe for 60s in normal mode then simulate Shabbat/conservation mode for another 60s; confirm screen never goes dark and no crashes occur in the simulator log

---

## Dependencies

```
T001 → T002 → T003 → T004 → T005   (sequential: DisplayService built before wired into MainView)
T005 → T006, T007                   (parallel verification after core integration)
T006, T007 → T008 → T009            (build and smoke-test last)
```

## Parallel Execution Opportunities

- T006 and T007 can run in parallel (different concerns, no shared file edits)
- T008 and T009 are sequential (must build before testing)

## Implementation Strategy (MVP)

- **MVP = US1 + US2** (T001–T005): Screen always on in both normal and Shabbat modes
- **US3** (T006–T007): Architectural verification — quick and low-risk
- **Polish** (T008–T009): Build + smoke test to confirm everything compiles and runs
