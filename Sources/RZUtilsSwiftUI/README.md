# RZUtilsSwiftUI

RZUtilsSwiftUI is a collection of SwiftUI components and extensions that enhance the SwiftUI development experience with custom views and utilities.

## Features

### Custom Views

- **ToggledTextField**
  - Text field with toggle functionality
  - Customizable appearance
  - State management integration
- **DynamicStack**
  - Adaptive stack layout
  - Responsive to content size
  - Automatic orientation handling

### Color Management

- **Color Extensions**
  - Hex color support
  - Color manipulation utilities
  - Theme integration
  - Color scheme adaptation

## Usage Examples

### ToggledTextField

```swift
struct ContentView: View {
    @State private var isEnabled = true
    @State private var text = ""
    
    var body: some View {
        ToggledTextField(
            text: $text,
            isEnabled: $isEnabled,
            placeholder: "Enter text"
        )
    }
}
```

### DynamicStack

```swift
struct ContentView: View {
    var body: some View {
        DynamicStack {
            Text("First Item")
            Text("Second Item")
            Text("Third Item")
        }
    }
}
```

### Color Extensions

```swift
// Create color from hex
let color = Color(hex: "#FF5733")

// Create color with opacity
let semiTransparent = color.opacity(0.5)

// Get hex representation
let hexString = color.toHex()
```

## Requirements

- Swift 5.0+
- iOS 14.0+ / macOS 11.0+
- Xcode 12.0+

## Installation

Add RZUtilsSwiftUI to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/rzutils.git", from: "1.0.0")
]
```

## Dependencies

- SwiftUI
- Foundation

## License

This library is available under the MIT license. See the LICENSE file for more information. 