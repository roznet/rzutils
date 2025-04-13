# RZData

RZData is a powerful Swift library for data manipulation and analysis, providing a DataFrame implementation similar to pandas in Python. It offers efficient data structures and operations for handling tabular data with support for various statistical and mathematical operations.

## Features

### Core Data Structures

- **DataFrame**: A two-dimensional, size-mutable, potentially heterogeneous tabular data structure
  - Generic over index type (I), value type (T), and field/column name type (F)
  - Supports labeled columns and rows
  - Maintains sorted order of indexes for efficient operations

### Data Operations

- **GroupBy**: Powerful grouping and aggregation operations
  - Group data by specific fields
  - Apply statistical functions to grouped data
  - Support for custom aggregation functions

### Statistical Functions

- **Basic Statistics**
  - Mean, median, mode
  - Standard deviation and variance
  - Minimum and maximum values
  - Sum and count operations

- **Advanced Statistics**
  - Quantile calculations with multiple interpolation methods
  - Linear regression
  - Cumulative sum operations
  - Value statistics and categorical statistics

### Data Manipulation

- **Interpolation**: Various interpolation methods for filling missing data
- **Value Transformation**: Operations for transforming and cleaning data
- **Index Management**: Efficient handling of sorted indexes

## Usage Examples

### Creating a DataFrame

```swift
// Create a DataFrame with Double values and String field names
var df = DataFrame<Int, Double, String>()

// Add data
try df.append(field: "temperature", element: 25.5, for: 1)
try df.append(field: "humidity", element: 60.0, for: 1)

// Access data
if let tempColumn = df["temperature"] {
    print(tempColumn.values) // [25.5]
}
```

### Statistical Operations

```swift
// Calculate basic statistics
let mean = df.mean()
let median = df.median()
let stdDev = df.standardDeviation()

// Calculate quantiles
let quantiles = df.quantiles([0.25, 0.5, 0.75])
```

### Grouping and Aggregation

```swift
// Group data and calculate statistics
let grouped = df.groupBy { $0["category"] }
let groupStats = grouped.aggregate { group in
    return [
        "count": group.count,
        "mean": group.mean(),
        "std": group.standardDeviation()
    ]
}
```

## Requirements

- Swift 5.0 or later
- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+

## Installation

Add RZData to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/rzutils.git", from: "1.0.0")
]
```

## License

This library is available under the MIT license. See the LICENSE file for more information.
