# RZUtilsSwift

RZUtilsSwift is a Swift-native utility library that provides modern Swift implementations of common utilities and extensions. It complements the Objective-C based RZUtils library with Swift-specific features and modern Swift paradigms.

## Features

### Units and Measurements

- **Dimensions and Units**
  - Custom unit converters (InverseLinear, Tan)
  - Geometry-specific units and measurements
  - Integration with Foundation's Measurement system
- **NumberWithUnit**
  - Swift-native implementation of unit-aware numbers
  - Geometry-specific unit handling
  - Type-safe unit conversions

### Data and Storage

- **Settings and Security**
  - Secure keychain storage
  - Property wrapper for settings
  - Type-safe settings management
- **Data Extensions**
  - Swift-native data manipulation
  - Integration with RZData framework
  - Type-safe data operations

### Networking

- **Remote Operations**
  - URL validation and handling
  - Multipart request building
  - Secure remote operations
- **Crypto Extensions**
  - Cryptographic operations
  - Secure data handling
  - Hash functions

### Logging and Debugging

- **RZSLog**
  - Modern Swift logging system
  - Integration with OSLog
  - Structured logging
  - Performance logging
- **Attributed String**
  - Swift-native attributed string handling
  - Rich text formatting
  - String interpolation

### Time and Date

- **Time Interval Extensions**
  - Swift-native time handling
  - Time interval calculations
  - Date manipulation

### Regression Analysis

- **Regression Manager**
  - Statistical analysis
  - Curve fitting
  - Data modeling

## Usage Examples

### Units and Measurements

```swift
// Create a custom unit converter
let converter = UnitConverterInverseLinear(coefficient: 1.0)
let unit = Unit(symbol: "inv", converter: converter)

// Use geometry-specific units
let angle = RZNumberWithUnitGeometry(45.0, unit: .degree)
let radians = angle.convert(to: .radian)
```

### Secure Storage

```swift
// Store secure data
let secureItem = SecureKeyChainItem(key: "apiKey", service: "com.example.app")
secureItem.value = "secret-api-key".data(using: .utf8)

// Retrieve secure data
if let data = secureItem.value {
    let apiKey = String(data: data, encoding: .utf8)
}
```

### Logging

```swift
// Create a logger
let logger = RZLogger(subsystem: "com.example.app", category: "network")

// Log messages
logger.info("Network request started")
logger.error("Network error: \(error)")
```

### Networking

```swift
// Build multipart request
let builder = MultipartRequestBuilder()
builder.addField(name: "file", filename: "image.jpg", data: imageData, mimeType: "image/jpeg")
let request = builder.buildRequest(to: url)

// Validate URL
if let validURL = RZSRemoteURLFindValid.findValidURL(from: ["https://example.com", "https://backup.com"]) {
    // Use valid URL
}
```

## Requirements

- Swift 5.0+
- iOS 13.0+ / macOS 10.15+
- Xcode 12.0+

## Installation

Add RZUtilsSwift to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/rzutils.git", from: "1.0.0")
]
```

## Dependencies

- RZUtils (for some bridging functionality)
- Foundation
- OSLog (for logging)

## License

This library is available under the MIT license. See the LICENSE file for more information. 