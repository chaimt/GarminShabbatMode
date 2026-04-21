# Implementation Plan: Shabbat Time Display

**Branch**: `003-shabbat-time-display` | **Date**: 2026-04-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-shabbat-time-display/spec.md`

## Summary

Implement comprehensive time display functionality for Shabbat observance, including current time, astronomical calculations (sunrise/sunset), and Shabbat-specific times (candle lighting, end of Shabbat). Technical approach focuses on real-time updates, location-based astronomical calculations, and configurable timing preferences.

## Technical Context

**Language/Version**: Monkey C (Connect IQ SDK 4.0+)  
**Primary Dependencies**: Garmin Connect IQ SDK, Location services, Mathematical calculation libraries  
**Storage**: Location cache, time preferences, astronomical calculation cache  
**Testing**: Time calculation accuracy, location services integration, timezone handling  
**Target Platform**: Garmin devices with GPS and location services
**Project Type**: Garmin Connect IQ application feature enhancement  
**Performance Goals**: <500ms calculation time, <1s display updates, GPS acquisition within 30s  
**Constraints**: Limited floating-point precision, memory efficient calculations, battery-conscious GPS usage  
**Scale/Scope**: Real-time time display, daily astronomical calculations, configurable preferences

## Project Structure

### Documentation (this feature)

```text
specs/003-shabbat-time-display/
├── plan.md              # This file
├── spec.md              # Feature specification
├── tasks.md             # Implementation tasks and progress
└── context.md           # Feature context and directives
```

### Source Code (planned additions to existing structure)

Files already exist from base application (001):
- `src/models/TimeInfo.mc`, `Location.mc`, `TimeConfiguration.mc`
- `src/services/TimeService.mc`

New files to be created:

```text
src/
├── models/
│   ├── AstronomicalData.mc     # Sunrise/sunset calculation results
│   └── ShabbatTimes.mc         # Candle lighting and end of Shabbat times
├── services/
│   ├── LocationService.mc      # GPS and location acquisition
│   ├── AstronomicalService.mc  # Sunrise/sunset calculations
│   ├── ShabbatTimeService.mc   # Shabbat-specific time calculations
│   └── TimezoneService.mc      # Timezone handling and conversions
├── ui/
│   ├── TimeDisplayView.mc      # Main time display interface
│   ├── TimeSettingsView.mc     # Time preferences configuration
│   └── components/
│       ├── ClockComponent.mc   # Current time display
│       ├── SunTimesComponent.mc # Sunrise/sunset display
│       └── ShabbatTimesComponent.mc # Candle lighting/end times display
├── lib/
│   ├── calculations/
│   │   ├── SunPosition.mc      # Solar position algorithms
│   │   ├── TimeZoneUtils.mc    # Timezone conversion utilities
│   │   └── DateMath.mc         # Date/time mathematical operations
│   ├── formatters/
│   │   ├── TimeFormatter.mc    # Time string formatting
│   │   └── DateFormatter.mc    # Date string formatting
│   └── validators/
│       ├── LocationValidator.mc # GPS coordinate validation
│       └── TimeValidator.mc    # Time calculation validation
└── cache/
    ├── LocationCache.mc        # Cached location data
    └── CalculationCache.mc     # Cached astronomical calculations
```

**Structure Decision**: Modular architecture with separate services for different time calculations, cacheable data models for performance, and reusable UI components for different time displays.

## Dependencies

This feature enhancement depends on:
- **Base Application Framework**: Core app structure and UI framework
- **Location Services**: Device GPS and location capabilities
- **Real-time Updates**: Timer and update mechanisms

## Technical Requirements

### Location Services:
- **GPS Accuracy**: Within 100 meters for astronomical calculations
- **Fallback Options**: Network location, cached location, manual entry
- **Privacy**: User control over location sharing and storage
- **Battery**: Efficient GPS usage to preserve battery life

### Astronomical Calculations:
- **Algorithms**: Standard sunrise/sunset algorithms (sunrise equation)
- **Accuracy**: ±2 minutes compared to astronomical references
- **Precision**: Handle Garmin device mathematical limitations
- **Caching**: Cache daily calculations to reduce computation

### Time Management:
- **Real-time Updates**: Second-level accuracy for current time
- **Timezone Handling**: Automatic timezone detection and DST transitions
- **Performance**: Sub-second response for time queries
- **Synchronization**: Sync with device system time

### Shabbat Calculations:
- **Configurable Offsets**: User-defined minutes before/after sunset
- **Regional Customs**: Support different timing traditions
- **Accuracy**: Consistent with established Shabbat timing sources
- **Validation**: Cross-check calculations with known references

### Error Handling:
- **Location Unavailable**: Graceful degradation with cached data
- **Calculation Errors**: Fallback to approximate times
- **Timezone Issues**: Default to device timezone settings
- **Invalid Coordinates**: Request location re-acquisition