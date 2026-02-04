# RZUtils

> A collection of Swift and Objective-C utility libraries for data analysis, units, storage, UI components, and Foundation extensions.

Install: Add via SPM — `https://github.com/nickinade/rzutils`

## Architecture

Five SPM targets with clear dependency chain:
```
RZData (independent)
RZUtils (depends: FMDB)
RZUtilsSwift (depends: RZUtils, RZData)
RZUtilsUniversal (depends: RZUtils)
RZUtilsSwiftUI (depends: RZUtilsSwift)
```

## Modules

### RZData
Pandas-inspired DataFrame for Swift — tabular data with typed indexes, columns, statistics, interpolation, and regression. Pure Swift, uses Accelerate for performance.
Key exports: `DataFrame`, `ValueStats`, `CategoricalStats`
→ Full doc: rzdata.md

### RZUtils
Objective-C foundation utilities: custom unit system (`GCUnit`), statistics series (`GCStatsDataSerie`), Foundation category extensions, file management, logging, and database helpers.
Key exports: `GCUnit`, `GCNumberWithUnit`, `GCStatsDataSerie`, `RZFileOrganizer`, `RZLog`
→ Full doc: rzutils-objc.md

### RZUtilsSwift
Swift-native utilities: property wrappers for settings/keychain, custom `Dimension` types (heart rate, fuel flow, climb gradient), networking, logging, and bridging extensions for RZUtils types.
Key exports: `UserStorage`, `CodableSecureStorage`, `RZSLog`, `MultipartRequestBuilder`, `RegressionManager`
→ Full doc: rzutils-swift.md

### RZUtilsUniversal
Cross-platform (iOS/macOS) Objective-C graph rendering system with data source protocols, geometry transformations, and view configuration/theming.
Key exports: `GCSimpleGraphView`, `GCSimpleGraphCachedDataSource`, `RZViewConfig`
→ Full doc: rzutils-universal.md

### RZUtilsSwiftUI
Small SwiftUI component library: adaptive layout stack, toggled text field, and color extensions for hex/RGB.
Key exports: `DynamicStack`, `ToggledTextField`, `Color` extensions
→ Full doc: rzutils-swiftui.md
