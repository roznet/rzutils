# RZUtilsSwiftUI

> Small SwiftUI component library: adaptive layout, toggled text fields, and color extensions.

## Intent

Lightweight SwiftUI utilities for apps using the RZUtils ecosystem. Kept minimal — only components that are genuinely reusable across multiple apps. Depends on `RZUtilsSwift` (not `RZUtils` directly).

## Architecture

```
Sources/RZUtilsSwiftUI/
├── DynamicStack.swift       # Adaptive HStack/VStack based on size class
├── ToggledTextField.swift   # Text field with view/edit toggle
└── ColorExtensions.swift    # Color init from hex/RGB strings
```

## Usage Examples

```swift
// Adaptive layout — HStack on wide screens, VStack on narrow
DynamicStack(spacing: 12) {
    Text("Label")
    Text("Value")
}

// Editable text field with toggle
ToggledTextField(text: $name, image: "person") { newValue in
    save(newValue)
}

// Color from hex or RGB string
let color1 = Color(hex: "#FF8000")
let color2 = Color(rgb: "rgb(255, 128, 0)")
```

## Key Choices

- **`DynamicStack`** reads `horizontalSizeClass` from environment — uses `HStack` for `.regular`, `VStack` for `.compact`. Configurable alignment and spacing.
- **`ToggledTextField`** shows a pencil icon in view mode, checkmark in edit mode. Optional leading `systemImage`. Action callback fires on commit.
- **Color extensions** support both `#RRGGBB` hex and `rgb(r, g, b)` CSS-style strings. Computed properties `.hex` and `.rgb` for reverse conversion.

## Patterns

- ViewBuilder-based APIs for composability
- Environment values for responsive behavior
- Minimal external dependencies (only `RZUtilsSwift`, no ObjC)

## References

- Depends on: [RZUtilsSwift](./rzutils-swift.md)
