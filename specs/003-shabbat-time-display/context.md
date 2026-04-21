# Feature Context

**Feature**: Shabbat Time Display
**Mission**: Implement comprehensive time display showing current time, astronomical times, and Shabbat-specific times for proper observance
**Code Paths**: src/models/, src/services/, src/ui/, src/lib/calculations/

## Discovered Directives (AI-Enhanced)

**Constitution**: [Will be populated from constitution.md if available]

**Personas**:
- Orthodox/Conservative Jewish user requiring precise Shabbat timing
- Garmin device user wanting reliable time information
- Traveler needing location-aware time calculations
- Developer implementing time-sensitive religious applications

**Rules**:
- Time calculations must be accurate to within ±2 minutes of authoritative sources
- Must handle location changes and timezone transitions seamlessly  
- Real-time updates must not drain battery excessively
- Must provide fallback when location services unavailable
- UI must be clearly readable in all lighting conditions
- Calculations must work offline after initial GPS acquisition

**Skills**:
- Astronomical calculation algorithms (sunrise/sunset equations)
- Real-time UI updates and timer management
- GPS and location services integration
- Timezone and daylight saving time handling
- Mathematical precision on resource-constrained devices
- Caching strategies for performance optimization
- Religious time calculation accuracy requirements

## Relevant Skills (AI-Selected)

**Directives**: Real-time application development, location-based services, astronomical calculations
**Research**: Sunrise/sunset algorithms, Jewish time calculation standards, Garmin Connect IQ location APIs, timezone handling libraries
**Gateway**: GPS accuracy requirements, mathematical precision limitations, battery usage constraints