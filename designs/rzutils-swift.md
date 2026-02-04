# RZUtilsSwift

> Swift-native utilities: property wrappers for storage, custom Dimension types, networking, logging, and ObjC bridging.

## Intent

Modern Swift layer that wraps and extends RZUtils (ObjC). Provides idiomatic Swift APIs: property wrappers for settings, `Dimension` subclasses for domain-specific units, structured logging, and protocol conformances for ObjC types. Depends on both `RZUtils` and `RZData`.

## Architecture

```
Sources/RZUtilsSwift/
├── SettingsPropertyStorage.swift  # Property wrappers: UserStorage, CodableStorage, SecureKeyChainItem
├── DimentionsAndUnits.swift       # Custom Dimension subclasses + UnitConverter extensions
├── RZSLog.swift                   # OSLog-based structured logging
├── MultipartRequestBuilder.swift  # HTTP multipart form-data builder
├── RegressionManager.swift        # Reference-based regression testing
├── RZUtilsExensions.swift         # ObjC bridging: Sequence/Comparable for GCStatsDataSerie, GCNumberWithUnit
├── RZDataExtensions.swift         # DataFrame extensions bridging to RZUtils
├── RZNumberWithUnitGeometry.swift # Geometry measurements with units
├── RZSRemoteURLFindValid.swift    # Sequential URL validity checker
├── Secrets.swift                  # JSON-based secrets loading
├── RZSAttributedString.swift      # Attributed string helpers
├── CryptoExtensions.swift         # Hashing/crypto via CommonCrypto
└── TimeIntervalExtension.swift    # TimeInterval helpers
```

## Usage Examples

```swift
// Property wrappers for settings
enum SettingsKey: String { case theme, unitSystem }
@UserStorage<SettingsKey, String>(key: .theme, defaultValue: "light")
var currentTheme: String

@CodableSecureStorage<SettingsKey, Credentials>(key: .credentials, service: "myApp")
var credentials: Credentials?

// Custom dimensions
let speed = Measurement(value: 500, unit: UnitSpeed.feetPerMinute)
let inKnots = speed.converted(to: .knots)

let heartRate = Measurement(value: 145, unit: UnitHeartRate.beatsPerMinute)
let gradient = Measurement(value: 3.5, unit: UnitClimbGradient.percent)

// Logging
RZSLog.info("Processing \(count) records")
RZSLog.error("Failed to load: \(error)")
```

## Key Choices

### Property Wrappers

| Wrapper | Backend | Use Case |
|---------|---------|----------|
| `UserStorage<K,T>` | UserDefaults | Simple preferences |
| `CodableStorage<K,T>` | UserDefaults (JSON) | Complex Codable values |
| `OptionalCodableStorage<K,T>` | UserDefaults (JSON) | Optional complex values |
| `CodableSecureStorage<K,T>` | Keychain | Sensitive Codable data |
| `UnitStorage<K,U>` | UserDefaults | Unit preferences |
| `EnumStorage<K,T>` | UserDefaults | Enum values (rawValue) |

All use a `Key` type conforming to `RawRepresentable` where `RawValue == String`.

### Custom Dimensions

Built for aviation/fitness domains:

- `UnitHeartRate` — bpm
- `UnitPercent` — %
- `UnitDimensionLess` — scalar
- `UnitFuelFlow` — gph, lph
- `UnitAngularVelocity` — rpm, deg/sec
- `UnitClimbGradient` — %, ft/nm, degrees (uses `UnitConverterTan`)

Standard unit extensions: `UnitSpeed` (pace: min/km, min/mi, sec/km, fpm), `UnitEnergy` (ft-lbs, Nm), `UnitAngle` (semicircle).

### Custom Unit Converters

- `UnitConverterInverseLinear` — `1/x * coefficient + offset` (for pace-like units)
- `UnitConverterTan` — `outsideMultiplier * tan(insideMultiplier * x)` (for gradient angles)

## Patterns

- **Property wrapper `Key` pattern**: All wrappers are generic over `Key: RawRepresentable` — define an enum for your settings keys, use it across all wrappers for consistency.
- **`SecureKeyChainItem`** uses `service` + `account` (key) for identification. Set `value = nil` to delete.
- **`RegressionManager`** stores reference JSON per test class/method — call `record()` during test, then `verify()` to compare against stored reference.

## Gotchas

- **File is named `DimentionsAndUnits.swift`** (typo preserved for consistency).
- **`UnitConverterInverseLinear`** is `internal` (not `public`) — custom dimensions using it must be in-module.
- **`GCNumberWithUnit` arithmetic operators** (in `RZUtilsExensions.swift`) convert to lhs unit before computing — order matters for mixed-unit operations.
- **`@retroactive` conformances** used for `GCStatsDataSerie: Sequence` and `GCNumberWithUnit: Comparable` — these are applied from Swift to ObjC types.

## References

- Depends on: [RZUtils ObjC](./rzutils-objc.md), [RZData](./rzdata.md)
- Used by: [RZUtilsSwiftUI](./rzutils-swiftui.md)
- Tests: `Tests/RZUtilsTests/`
