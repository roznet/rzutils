//
//  SwiftUIView.swift
//  
//
//  Created by Brice Rosenzweig on 09/09/2023.
//

import SwiftUI

public struct DynamicStack<Content : View> : View {
    var horizontalAlignment = HorizontalAlignment.center
    var verticalAlignment = VerticalAlignment.center
    var spacing: CGFloat? = nil
    @ViewBuilder public var content: () -> Content
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    public init(horizontalAlignment: HorizontalAlignment = HorizontalAlignment.center, 
                verticalAlignment: VerticalAlignment = VerticalAlignment.center,
                spacing: CGFloat? = nil,
                content: @escaping () -> Content) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }
    
    public var body: some View {
        switch horizontalSizeClass {
        case .regular:
            hStack
        case .compact,.none:
            vStack
        case .some(_):
            vStack
        }
    }
    
    var hStack: some View {
        HStack(alignment: verticalAlignment, spacing: spacing, content: content)
    }
    var vStack: some View {
        VStack(alignment: horizontalAlignment,spacing: spacing, content: content)
    }
}

#Preview {
    VStack {
        Text("A")
        Text("B")
    }
}


