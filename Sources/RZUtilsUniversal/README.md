# RZUtilsUniversal

RZUtilsUniversal is a cross-platform utility library that provides common functionality for both iOS and macOS applications, with a focus on data visualization and UI components.

## Features

### Simple Graph System

- **Graph View**
  - Customizable graph rendering
  - Support for multiple data series
  - Interactive data visualization
  - Performance-optimized drawing
- **Graph Geometry**
  - Coordinate system management
  - Scale and transform utilities
  - Data point mapping
- **Cached Data Source**
  - Efficient data management
  - Performance optimization
  - Memory management

### Color Management

- **Color Utilities**
  - Hex string conversion
  - Color manipulation
  - Cross-platform color handling
- **Gradient Support**
  - Custom gradient creation
  - Gradient color management
  - Visual effect utilities

### View Configuration

- **View Config**
  - Unified view settings
  - Theme management
  - Cross-platform appearance
- **Bezier Path Helpers**
  - Quartz integration
  - Path manipulation
  - Drawing utilities

## Usage Examples

### Creating a Simple Graph

```objective-c
// Create a graph view
GCSimpleGraphView *graphView = [[GCSimpleGraphView alloc] initWithFrame:frame];

// Configure the view
graphView.config = [RZViewConfig defaultConfig];

// Set up data source
GCSimpleGraphCachedDataSource *dataSource = [[GCSimpleGraphCachedDataSource alloc] init];
[dataSource addSeries:series1 withColor:[UIColor blueColor]];
[dataSource addSeries:series2 withColor:[UIColor redColor]];

graphView.dataSource = dataSource;
```

### Color Management

```objective-c
// Create color from hex
UIColor *color = [UIColor colorWithHexString:@"#FF5733"];

// Convert color to hex
NSString *hexString = [color hexString];

// Create gradient
GCViewGradientColors *gradient = [[GCViewGradientColors alloc] initWithStartColor:startColor endColor:endColor];
```

### View Configuration

```objective-c
// Create view configuration
RZViewConfig *config = [RZViewConfig defaultConfig];

// Customize appearance
config.backgroundColor = [UIColor whiteColor];
config.gridColor = [UIColor lightGrayColor];
config.textColor = [UIColor blackColor];

// Apply to view
view.config = config;
```

## Requirements

- iOS 13.0+ / macOS 10.15+
- Objective-C or Swift (with bridging header)
- Xcode 12.0+

## Installation

Add RZUtilsUniversal to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/rzutils.git", from: "1.0.0")
]
```

## Dependencies

- Foundation
- UIKit (iOS) / AppKit (macOS)
- Core Graphics
- Quartz Core

## License

This library is available under the MIT license. See the LICENSE file for more information. 