# RZUtils

RZUtils is a comprehensive utility library for iOS/macOS development, providing a wide range of helper classes, extensions, and utilities for common development tasks. It includes functionality for unit handling, file management, logging, performance monitoring, and more.

## Features

### Units and Measurements

- **GCUnit**: Comprehensive unit system for handling various types of measurements
  - Linear units (distance, speed, etc.)
  - Time-based units (date, time of day, elapsed time)
  - Calendar units
  - Performance range units
  - Log scale units
  - Inverse linear units
- **GCNumberWithUnit**: Number with associated unit for easy conversion and display

### Foundation Extensions

- **Date Handling**
  - NSDate extensions for common date operations
  - Calendar and date components helpers
  - Time zone and formatting utilities
- **String Manipulation**
  - Camel case conversion
  - String mangling utilities
  - Formatting helpers
- **Collection Helpers**
  - Dictionary extensions
  - Array mapping and filtering
  - Thread-safe operations

### System Utilities

- **File Management**
  - File organization and path handling
  - Remote file downloading
  - File system operations
- **System Information**
  - Device and OS information
  - Memory management
  - Performance monitoring
- **Logging**
  - Comprehensive logging system
  - Log bridging
  - Performance logging

### Data Handling

- **XML Processing**
  - XML element handling
  - XML reader utilities
- **Database Helpers**
  - FMResultSet extensions
- **Data Table Management**
  - Structured data handling
  - Table operations

### Application Support

- **Configuration**
  - App configuration management
  - Settings handling
- **Timing**
  - App timer utilities
  - Timestamp management
- **Dependencies**
  - Dependency management
  - Version checking

## Usage Examples

### Unit Handling

```objective-c
// Create a number with unit
GCNumberWithUnit *speed = [GCNumberWithUnit numberWithUnitName:@"kph" andValue:60.0];

// Convert between units
GCNumberWithUnit *speedInMph = [speed convertToUnitName:@"mph"];

// Display formatted value
NSString *formatted = [speed formatDouble];
```

### Date Operations

```objective-c
// Get start of day
NSDate *startOfDay = [[NSDate date] rzStartOfDay];

// Calculate time interval
NSTimeInterval interval = [date1 rzTimeIntervalSinceDate:date2];

// Format date components
NSString *formatted = [components rzFormattedString];
```

### File Management

```objective-c
// Organize files
[RZFileOrganizer organizeFile:filePath inCategory:@"Documents"];

// Download remote file
[RZRemoteDownload downloadFromURL:url toPath:localPath completion:^(NSError *error) {
    if (!error) {
        // Handle successful download
    }
}];
```

### Logging

```objective-c
// Log messages
RZLog(RZLogLevelInfo, @"Application started");
RZLog(RZLogLevelError, @"Error occurred: %@", error);

// Performance logging
RZPerformanceLog(@"Operation completed in %f seconds", duration);
```

## Requirements

- iOS 13.0+ / macOS 10.15+
- Objective-C or Swift (with bridging header)

## Installation

Add RZUtils to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/rzutils.git", from: "1.0.0")
]
```

For Objective-C projects, you'll need to create a bridging header and import the necessary headers.

## License

This library is available under the MIT license. See the LICENSE file for more information. 