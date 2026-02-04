# RZUtils (Objective-C)

> Foundation-level Objective-C utilities: custom unit system, statistics series, Foundation extensions, file management, and logging.

## Intent

The original utility layer — provides low-level building blocks used across multiple apps (ConnectStats, FlightLog1000). Written in Objective-C for historical reasons but fully bridgeable to Swift. The unit system (`GCUnit`) predates Foundation's `Measurement`/`Dimension` and remains in use alongside it.

## Architecture

```
Sources/RZUtils/
├── units/          # GCUnit hierarchy + GCNumberWithUnit
├── stats/          # GCStatsDataSerie, data points, clustering, date buckets
├── foundation/     # NSDate, NSString, NSArray, NSDictionary extensions
├── utils/          # RZFileOrganizer, RZLog, RZRemoteDownload, RZAppConfig, etc.
├── datatable/      # TSDataTable, TSDataRow, TSDataPivot (tabular display)
├── LibComponentLogging/  # LCLLogFile
└── include/        # Public headers (LCLLogFileConfig, RZMacros, RZSimNeedle)
```

### Units Subsystem

Hierarchy of `GCUnit` subclasses for measurement conversion and formatting:

| Class | Purpose |
|-------|---------|
| `GCUnit` | Base — key-based lookup, formatting, reference unit |
| `GCUnitLinear` | `value * multiplier + offset` |
| `GCUnitInverseLinear` | `multiplier / value + offset` (pace) |
| `GCUnitDate` | Date formatting with calendar |
| `GCUnitTimeOfDay` | Time-of-day display |
| `GCUnitCalendarUnit` | Calendar component units |
| `GCUnitElapsedSince` | Time elapsed from reference |
| `GCUnitPerformanceRange` | Zone-based performance |
| `GCUnitLogScale` | Logarithmic conversions |

`GCNumberWithUnit` pairs a `double` value with a `GCUnit` — provides formatting, arithmetic, conversion, and scanning from strings.

### Statistics Subsystem

- `GCStatsDataSerie` — ordered series of `GCStatsDataPoint` (x, y pairs)
- `GCStatsDataSerieWithUnit` — series with unit metadata
- `GCStatsDataSerieFilter` — filtering operations
- `GCStatsDateBuckets` — bucketing by calendar intervals
- `GCStatsCluster` — clustering algorithms
- `GCStatsFunctions` — standalone statistical functions

### Foundation Extensions

- `NSDate+RZHelper` — start/end of day, relative dates, formatting
- `NSCalendar+RZHelper` — calendar operations
- `NSString+CamelCase` — case conversion
- `NSString+Mangle` — string obfuscation
- `NSArray+Map` — functional operations (map, filter)
- `NSDictionary+RZHelper` — dictionary utilities
- `CLLocation+RZHelper` — location helpers

### System Utilities

- `RZFileOrganizer` — file path management (documents, bundles, write dir)
- `RZLog` — logging with levels and file output
- `RZRemoteDownload` — URL download with delegate callbacks
- `RZAppConfig` — app configuration
- `RZPerformance` / `RZAppTimer` — timing
- `RZMemory` — memory tracking
- `GCXMLElement` / `GCXMLReader` — XML parsing

## Key Choices

- **`GCUnit` uses string keys** for lookup (e.g., `"meter"`, `"kilogram"`), not enum — allows dynamic registration.
- **`GCStatsDataSerie` is the ObjC counterpart to `DataFrame`** — simpler (single y-value series), used extensively in ConnectStats.
- **FMDB dependency** — `FMResultSet+RZHelper` extensions for database result handling.
- **Categories over subclassing** — Foundation extensions use Objective-C categories throughout.

## Patterns

- All public headers in `include/` for umbrella header inclusion
- `NS_ASSUME_NONNULL_BEGIN`/`END` blocks for Swift interop
- `@objc` compatible APIs designed for bridging
- Thread-safety via `NSLock` in performance-critical utilities

## Gotchas

- `GCUnit` and Foundation `Dimension` coexist — don't confuse them. `RZUtilsSwift` bridges between the two.
- `RZLog` must be configured early in app lifecycle for file output.
- `GCStatsDataSerie` is **not** generic — always `double` x/y values.

## References

- Swift bridge: [RZUtilsSwift](./rzutils-swift.md) — `RZUtilsExensions.swift` adds Swift conformances
- Graph rendering: [RZUtilsUniversal](./rzutils-universal.md) — uses `GCStatsDataSerie` as data source
- Tests: `Tests/RZUtilsObjCTests/`
