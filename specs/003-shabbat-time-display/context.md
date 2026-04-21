# Feature Context

**Feature**: Shabbat Time Display
**Mission**: Implement comprehensive time display showing current time, astronomical times, and Shabbat-specific times for proper observance
**Code Paths**: src/models/, src/services/, src/ui/, src/lib/calculations/

## Technical Context

**Language**: Monkey C (Connect IQ SDK 4.0+)
**Key APIs**: Toybox.Position (GPS), Toybox.Time, Toybox.Math
**Permissions Required**: Positioning (already in manifest)
**Dependencies**: Base application (001) must be complete

## Personas

- Orthodox/Conservative Jewish user requiring precise Shabbat timing
- Garmin device user wanting reliable time information
- Traveler needing location-aware time calculations

## Constraints

- Time calculations must be accurate to within +/-2 minutes of authoritative sources
- Must handle location changes and timezone transitions seamlessly
- Real-time updates must not drain battery excessively
- Must provide fallback when location services unavailable
- Calculations must work offline after initial GPS acquisition
- Limited floating-point precision on Garmin devices

## Key Technical Challenges

- Astronomical calculation algorithms (sunrise equation) with limited math precision
- Battery-efficient GPS usage patterns
- Timezone and DST handling across travel
- Caching strategy for daily calculations
- Supporting regional customs for Shabbat timing offsets
