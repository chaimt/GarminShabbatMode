# Implementation Plan: Forerunner 965 Device Support

**Branch**: `002-forerunner-965-support` | **Date**: 2026-04-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-forerunner-965-support/spec.md`

## Summary

Add comprehensive support for Garmin Forerunner 965 devices to the ShabbatMode application, including device detection, UI optimization for device specifications, and integration with device-specific hardware capabilities. Technical approach focuses on device profile management and adaptive UI rendering.

## Technical Context

**Language/Version**: Monkey C (Connect IQ SDK 4.0+)  
**Primary Dependencies**: Garmin Connect IQ SDK, Device-specific APIs  
**Storage**: Device-specific configuration files, optimized layouts  
**Testing**: Forerunner 965 simulator and physical device testing  
**Target Platform**: Garmin Forerunner 965 (454x454 pixel display, touchscreen)
**Project Type**: Garmin Connect IQ application enhancement  
**Performance Goals**: <5s launch time, <30MB memory usage on Forerunner 965  
**Constraints**: Device-specific memory limits, screen resolution optimization, touch interface requirements  
**Scale/Scope**: Single device model support, 3-4 device-specific screens, hardware integration

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

[Gates will be determined based on constitution file review]

## Project Structure

### Documentation (this feature)

```text
specs/002-forerunner-965-support/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code Enhancement (repository root)

```text
src/
├── models/
│   ├── DeviceProfile.mc        # Device-specific configuration
│   ├── FR965Profile.mc         # Forerunner 965 specific profile
│   └── HardwareCapabilities.mc # Hardware detection and capabilities
├── services/
│   ├── DeviceDetectionService.mc # Device model detection
│   ├── UIOptimizationService.mc  # Dynamic UI scaling
│   └── HardwareService.mc       # Device-specific hardware integration
├── ui/
│   ├── fr965/                  # Forerunner 965-specific UI components
│   │   ├── FR965MainView.mc    # Optimized main view
│   │   ├── FR965SettingsView.mc # Optimized settings view
│   │   └── FR965Components.mc   # Device-specific UI components
│   └── adaptive/               # Adaptive UI framework
│       ├── ScreenAdapter.mc    # Screen resolution adaptation
│       └── LayoutManager.mc    # Dynamic layout management
└── lib/
    ├── device/                 # Device-specific utilities
    │   ├── FR965Utils.mc       # Forerunner 965 utilities
    │   ├── CapabilityDetector.mc # Hardware capability detection
    │   └── PerformanceProfiler.mc # Device performance optimization
    └── compatibility/          # Cross-device compatibility
        ├── DeviceRegistry.mc   # Supported device registry
        └── FallbackHandler.mc  # Unsupported feature fallbacks

resources/
├── layouts/
│   └── fr965/                  # Forerunner 965-specific layouts
│       ├── fr965_main_layout.xml
│       └── fr965_settings_layout.xml
├── strings/
│   └── fr965_strings.xml       # Device-specific strings
└── images/
    └── fr965/                  # Optimized images for Forerunner 965
        ├── icons_454x454/      # High-resolution icons
        └── backgrounds/        # Device-optimized backgrounds

manifest.xml                    # Updated with Forerunner 965 support
```

**Structure Decision**: Extension of the base application with device-specific modules that plug into the existing architecture. Uses factory pattern for device detection and adaptive UI components that scale based on device capabilities.

## Dependencies

This feature enhancement depends on:
- **Base Application (001-base-application)**: Core application framework must be implemented
- **Device Registry**: Requires base device detection framework
- **UI Framework**: Builds on existing UI service architecture

## Device-Specific Considerations

### Forerunner 965 Specifications:
- **Screen**: 454x454 pixel AMOLED touchscreen
- **Memory**: 32GB storage, limited runtime memory
- **Sensors**: GPS, heart rate, accelerometer, gyroscope, compass
- **Input**: Touchscreen + 5 physical buttons
- **Battery**: Optimized for multi-day usage
- **OS**: Garmin OS with Connect IQ runtime

### Technical Approach:
1. **Device Detection**: Runtime detection of Forerunner 965 through Connect IQ APIs
2. **UI Scaling**: Adaptive layouts that scale to 454x454 resolution with appropriate touch targets
3. **Performance Optimization**: Memory-efficient loading of device-specific resources
4. **Capability Mapping**: Dynamic feature enablement based on available hardware
5. **Fallback Support**: Graceful degradation for unsupported features