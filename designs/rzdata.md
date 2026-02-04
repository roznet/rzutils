# RZData

> Pandas-inspired generic DataFrame for Swift with statistics, interpolation, and regression.

## Intent

Provides a typed, column-oriented tabular data structure for time series and numerical analysis in Swift. Originated from FlightLog1000 for flight data analysis. Should remain **independent** of all other RZUtils modules — no ObjC dependencies.

## Architecture

```
Sources/RZData/
├── DataFrame.swift          # Core struct + Sequence conformance (~1170 lines)
├── GroupBy.swift             # extract() aggregation between index boundaries
├── Statistics.swift          # Accelerate-powered stats (sum, mean, quantile, etc.)
├── ValueStats.swift          # Running numerical stats accumulator
├── CategoricalStats.swift    # Frequency/categorical stats accumulator
├── Interpolation.swift       # Linear + cubic spline interpolation
├── LinearRegression.swift    # Per-field linear regression
├── CumSum.swift              # Cumulative sum
├── ApproximatelyEqual.swift  # SE-0259 floating-point comparison
└── FoundationExtensions.swift # Measurement/Date async helpers
```

### Core Generic Parameters

```swift
struct DataFrame<I: Comparable & Hashable, T, F: Hashable>: Sequence
```

- **`I`** — Index type (row labels). Must be sorted ascending. Common: `Date`, `Int`, `Double`.
- **`T`** — Value type. Often `Double`, but can be any type.
- **`F`** — Field type (column names). Often `String` or an enum.

### Internal Storage

- `indexes: [I]` — sorted array of row identifiers
- `values: [F: [T]]` — dictionary of column arrays, each parallel to `indexes`
- All columns share the same index array — consistency enforced on mutation

### Key Types

- `Column` — slice with `indexes: [I]` + `values: [T]`, has `first`/`last` `Point`
- `Point` — single `(index: I, value: T)`
- `Row` — `typealias [F: T]`

## Usage Examples

```swift
// Build a DataFrame
var df = DataFrame<Date, Double, String>()
try df.append(field: "altitude", element: 3500.0, for: timestamp1)
try df.append(field: "speed", element: 120.0, for: timestamp1)

// Access columns and compute stats (T == Double)
let stats = df.describe()          // per-field count/mean/std/min/max
let avg = df.means()               // [F: Double]
let q = df.quantiles([0.25, 0.5, 0.75])

// Aggregate between boundaries
let grouped = try df.extractValueStats(indexes: boundaries, start: start, end: end)
// grouped is DataFrame<I, ValueStats, F> with .average, .max, .min per segment

// Interpolate at new indexes
let interp = df.interpolate(at: newIndexes)           // linear
let smooth = df.cubicSplineInterpolation(at: newIndexes) // cubic spline
```

## Key Choices

- **Sorted index invariant**: `append()` throws `inconsistentIndexOrder` if new index < last. Use `unsafeFastAppend()` only when caller guarantees order (perf-critical paths).
- **Accelerate for stats**: `sum()`, `mean()`, `variance()`, `movingAverage()`, `correlation()` use `vDSP` for vectorized operations on `[Double]`.
- **`extract()` is the core grouping primitive**: All aggregation (`extractValueStats`, `extractCategoricalStats`) builds on the generic `extract(extractIndexes:createCollector:updateCollector:completeCollector:)` function.
- **Quantile method**: Uses Excel R7 / pandas-compatible interpolation with `.linear`, `.lower`, `.higher`, `.midpoint`.
- **Cubic spline**: Natural boundary conditions, second derivatives computed via tridiagonal system, Accelerate-vectorized.

## Patterns

- **Specialized extensions**: Stats methods constrained to `where T == Double`. Equatable/comparison methods constrained to `where T: Equatable`.
- **Safe vs unsafe**: `append()` validates order; `unsafeFastAppend()` skips validation. Both maintain parallel column arrays.
- **`reserveCapacity(_:)`**: Call before bulk inserts for performance.
- **Sequence conformance**: Iterates as `(index: I, row: [F: T])` tuples.

## Gotchas

- **All columns share one index array** — appending a value for one field at a new index extends `indexes` for all fields. Missing fields get no entry (sparse).
- **`dropna()`** only works when `T: Equatable` with `Optional` — filters rows where any field is nil.
- **`merge()`** mutates in place; `merged()` returns a new DataFrame.
- **Index order check** added recently (`checkIndexOrderConsistency`) — validates the invariant, useful for debugging.
- **Int-indexed specializations** exist in `FoundationExtensions.swift` for binary search, sorted insert/remove on `[Int]`.

## References

- Tests: `Tests/RZUtilsTests/RZDataTests.swift`
- Used by: FlightLog1000, ConnectStats
- Related: [RZUtilsSwift](./rzutils-swift.md) has `RZDataExtensions.swift` bridging
