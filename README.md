# RZUtils

RZUtils is a collection of utility libraries for iOS and macOS development, providing a wide range of functionality from data manipulation to UI components. The library is organized into several specialized modules, each focusing on specific aspects of application development.

## Overview

RZUtils consists of the following sublibraries:

### [RZData](Sources/RZData/README.md)

A powerful data manipulation and analysis library, providing a DataFrame implementation similar to pandas in Python. It offers efficient data structures and operations for handling tabular data with support for various statistical and mathematical operations.

Key features:
- DataFrame implementation for tabular data
- Statistical analysis and calculations
- Data grouping and aggregation
- Interpolation and data transformation

### [RZUtils](Sources/RZUtils/README.md)

A comprehensive utility library providing helper classes, extensions, and utilities for common development tasks. It includes functionality for unit handling, file management, logging, and more.

Key features:
- Units and measurements system
- File management and organization
- Logging and debugging tools
- Foundation extensions
- System utilities

### [RZUtilsSwift](Sources/RZUtilsSwift/README.md)

A Swift-native utility library that provides modern Swift implementations of common utilities and extensions. It complements the Objective-C based RZUtils library with Swift-specific features and modern Swift paradigms.

Key features:
- Swift-native unit and measurement system
- Secure storage and settings management
- Modern logging system
- Networking utilities
- Regression analysis

### [RZUtilsSwiftUI](Sources/RZUtilsSwiftUI/README.md)

A collection of SwiftUI components and extensions that enhance the SwiftUI development experience with custom views and utilities.

Key features:
- Custom SwiftUI views (ToggledTextField, DynamicStack)
- Color management and theming
- SwiftUI-specific utilities

### [RZUtilsUniversal](Sources/RZUtilsUniversal/README.md)

A cross-platform utility library that provides common functionality for both iOS and macOS applications, with a focus on data visualization and UI components.

Key features:
- Simple graph system for data visualization
- Cross-platform color management
- View configuration and theming
- Drawing utilities

## Requirements

- Swift 5.0+
- iOS 13.0+ / macOS 10.15+
- Xcode 12.0+

## Installation

Add RZUtils to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/rzutils.git", from: "1.0.0")
]
```

You can also add specific sublibraries if you don't need the entire package:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/rzutils.git", from: "1.0.0"),
    .product(name: "RZData", package: "rzutils"),
    .product(name: "RZUtilsSwiftUI", package: "rzutils")
]
```

## Documentation

Each sublibrary has its own detailed documentation:
- [RZData Documentation](Sources/RZData/README.md)
- [RZUtils Documentation](Sources/RZUtils/README.md)
- [RZUtilsSwift Documentation](Sources/RZUtilsSwift/README.md)
- [RZUtilsSwiftUI Documentation](Sources/RZUtilsSwiftUI/README.md)
- [RZUtilsUniversal Documentation](Sources/RZUtilsUniversal/README.md)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This library is available under the MIT license. See the [LICENSE](LICENSE) file for more information.
