<!-- SYNC IMPACT REPORT
Version change: 0.0.0 → 1.0.0
Modified principles: N/A (initial ratification)
Added sections:
  - Core Principles (5 principles)
  - Technical Constraints (Garmin CIQ platform)
  - Development Workflow (CIQ build/test/deploy)
  - Governance
Templates requiring updates:
  - plan-template.md: ✅ Constitution Check section present, compatible
  - spec-template.md: ✅ Requirements section compatible with principles
  - tasks-template.md: ✅ Phase structure compatible with project scope
Follow-up TODOs: None
-->

# ShabbatMode Constitution

## Core Principles

### I. Shabbat Compliance First

Every design and implementation decision must prioritize respect for
Shabbat observance. The application exists to help observant users
continue wearing their Garmin watch during Shabbat without triggering
unnecessary electronic activity. Features that increase sensor usage
or user interaction during Shabbat are out of scope.

**Rationale**: The entire purpose of this application is religious
observance support. Any feature that conflicts with minimizing
electronic activity on Shabbat violates the project's reason for
existing.

### II. Always-On Display

The watch display must remain on at all times while ShabbatMode is
active. The screen must not go to sleep, dim to off, or require
user interaction to wake. A static, low-power watch face showing
the current time is the primary output.

**Rules**:
- Prevent the watch from entering sleep mode
- Display must remain visible without user touch or gesture
- Use the lowest acceptable brightness or burn-in-safe rendering
- Time display must remain accurate throughout Shabbat

### III. Minimal Sensor Footprint

Disable or suppress as many sensors as technically possible while
ShabbatMode is active. The goal is to reduce the watch to a
passive time-display device.

**Sensors to disable (where the Connect IQ API permits)**:
- GPS / GLONASS / location services
- Heart rate monitor (optical HR)
- Pulse oximeter (SpO2)
- Accelerometer / gyroscope (activity tracking)
- Barometer / altimeter
- Ambient light sensor (if controllable)
- Bluetooth data sync and notifications
- Wi-Fi connectivity

**Rationale**: Fewer active sensors means less electronic activity,
which aligns with the principle of minimizing melacha (creative
work) on Shabbat. It also preserves battery life.

### IV. Zero Interaction During Shabbat

Once ShabbatMode is activated, the user should not need to interact
with the watch at all. No button presses, no swipes, no taps
should be required or encouraged during Shabbat.

**Rules**:
- Activation happens before Shabbat begins (e.g., before candle
  lighting)
- Deactivation happens after Shabbat ends (e.g., after Havdalah)
- No alerts, notifications, or prompts during active mode
- Physical button presses should be suppressed or ignored where
  possible

### V. Simplicity and Reliability

The application must be simple, predictable, and reliable. A user
who activates ShabbatMode on Friday afternoon must be confident
the watch will still be showing the time on Saturday night. No
crashes, no unexpected exits, no complex configuration.

**Rules**:
- Minimal code paths, minimal state management
- No network calls or data sync during active mode
- Graceful handling of low battery (degrade to time-only, never
  crash)
- Single-purpose: show time, nothing else
- YAGNI — do not add features beyond the stated purpose

## Technical Constraints

**Platform**: Garmin Connect IQ (CIQ) SDK
**Language**: Monkey C
**App Type**: Watch Face (preferred) or Watch App — whichever
grants the most control over sensor suppression and always-on
behavior
**Target Devices**: Garmin watches supporting Connect IQ 3.0+
with always-on display capability (e.g., Venu series, fenix
series, epix series)
**Build System**: Garmin Connect IQ SDK / Monkey C compiler
**Testing**: Connect IQ Simulator for functional verification;
on-device testing required for sensor and display behavior
**Storage**: Minimal — only persist activation state and user
preferences (if any)
**Performance**: Must run for 25+ hours continuously (Friday
sunset through Saturday nightfall plus margin) without crash
or display loss

## Development Workflow

**Code Review**: All changes must be reviewed for Shabbat
compliance — no change should introduce new sensor activation
or user interaction requirements during active mode.

**Testing Gates**:
- Simulator test: App launches, displays time, does not crash
  over extended run
- Sensor audit: Verify disabled sensors remain off throughout
  the session via CIQ device logs
- Battery test: On-device 25-hour endurance run with ShabbatMode
  active
- Activation/deactivation: Clean transitions with no data loss

**Deployment**: Published via Garmin Connect IQ Store for end
users.

## Governance

This constitution defines the non-negotiable principles for the
ShabbatMode project. All pull requests and code reviews must
verify compliance with these principles.

**Amendment Process**:
1. Propose amendment with rationale
2. Verify amendment does not conflict with Principle I (Shabbat
   Compliance First)
3. Document change in constitution version history
4. Update dependent artifacts if principles change

**Versioning**: Constitution follows semantic versioning
(MAJOR.MINOR.PATCH). Principle removals or redefinitions require
a MAJOR bump. New principles or expanded guidance require MINOR.
Clarifications and typo fixes require PATCH.

**Compliance**: Every specification, plan, and implementation
task must trace back to at least one constitutional principle.
Features that cannot be justified under these principles should
not be built.

**Version**: 1.0.0 | **Ratified**: 2026-04-13 | **Last Amended**: 2026-04-13
