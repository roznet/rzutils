# RZUtilsUniversal

> Cross-platform (iOS/macOS) Objective-C graph rendering with data source protocols, geometry, and theming.

## Intent

Provides a reusable graphing system for data visualization that works on both UIKit and AppKit. Used primarily by ConnectStats for activity/performance graphs. Bridges to `RZUtils` for data types (`GCStatsDataSerie`) but remains UI-focused.

## Architecture

```
Sources/RZUtilsUniversal/
├── include/
│   └── GCSimpleGraphProtocol.h    # Data source protocol
└── simplegraph/
    ├── GCSimpleGraphView.h/m          # Main rendering view
    ├── GCSimpleGraphCachedDataSource.h/m  # Cached multi-series data source
    ├── GCSimpleGraphGeometry.h/m      # Coordinate space transforms
    ├── GCViewGradientColors.h/m       # Gradient color definitions
    ├── RZViewConfig.h/m               # Theme/appearance config
    ├── UIColor+HexString.h/m          # Hex color parsing
    └── NSBezierPath+QuartzHelper.h/m  # macOS drawing compat
```

### Component Roles

- **`GCSimpleGraphProtocol`** — defines what a data source must provide: series count, data points, colors, axis config
- **`GCSimpleGraphCachedDataSource`** — implements the protocol with caching, manages multiple series, color assignment, legend
- **`GCSimpleGraphView`** — the actual view; renders axes, grid, data series, handles touches/interaction
- **`GCSimpleGraphGeometry`** — maps data coordinates to screen coordinates, manages zoom/pan, calculates bounds

## Key Choices

- **Protocol-based data source** — graph view is decoupled from data representation. Any object conforming to `GCSimpleGraphProtocol` can drive the graph.
- **Cached data source** — avoids recomputation during rapid redraws (scrolling, zooming).
- **`RZViewConfig` for theming** — centralizes colors, fonts, grid styles. Change config to restyle all graphs.
- **Cross-platform via conditional compilation** — `#if TARGET_OS_IPHONE` for UIKit vs AppKit differences. `NSBezierPath+QuartzHelper` bridges macOS drawing to match iOS APIs.

## Patterns

- Data flow: `DataSource → Geometry (transform) → View (render)`
- Color management: `UIColor+HexString` for hex strings, `GCViewGradientColors` for gradient fills
- Series are indexed by integer; each series has its own color, line style, fill behavior

## Gotchas

- Depends on `RZUtils` for `GCStatsDataSerie` and `GCUnit` — these are the expected data types.
- macOS support requires `NSBezierPath+QuartzHelper` — don't remove it even if it looks unused on iOS.
- `RZViewConfig` is a singleton-like config — changes affect all views using the shared config.

## References

- Data types from: [RZUtils ObjC](./rzutils-objc.md)
- Tests: `Tests/RZUtilsObjCTests/`
