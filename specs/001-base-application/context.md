# Feature Context

**Feature**: Base Garmin ShabbatMode Application
**Mission**: Create foundational application structure for ShabbatMode functionality on Garmin devices
**Code Paths**: src/, resources/

## Technical Context

**Language**: Monkey C (Connect IQ SDK 4.0+)
**App Type**: Widget (declared in manifest.xml)
**Target Devices**: fenix6, fenix7, fr965, venu2, epix
**Permissions**: Positioning, Storage, Background

## Personas

- Garmin device user seeking Shabbat observance functionality

## Constraints

- Must follow Garmin Connect IQ development guidelines
- Application must be memory efficient (<50MB)
- Launch time must be under 5 seconds
- Must handle device integration gracefully via Connect IQ APIs

## Skills Required

- Garmin Connect IQ widget development (Monkey C, Toybox APIs)
- Device-specific UI design via resource qualifiers
- Configuration management via Toybox.Application.Storage
- Error handling and logging
