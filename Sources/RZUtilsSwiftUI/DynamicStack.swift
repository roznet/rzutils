//
//  DynamicStack.swift
//
//
//  Created by Brice Rosenzweig on 09/09/2023.
//

import SwiftUI

public struct DynamicStack<Content : View> : View {
    private let horizontalAlignment: HorizontalAlignment
    private let verticalAlignment: VerticalAlignment
    private let spacing: CGFloat?
    @ViewBuilder private let content: () -> Content

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init(horizontalAlignment: HorizontalAlignment = .center,
                verticalAlignment: VerticalAlignment = .center,
                spacing: CGFloat? = nil,
                @ViewBuilder content: @escaping () -> Content) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }

    private var layout: AnyLayout {
        horizontalSizeClass == .regular
            ? AnyLayout(HStackLayout(alignment: verticalAlignment, spacing: spacing))
            : AnyLayout(VStackLayout(alignment: horizontalAlignment, spacing: spacing))
    }

    public var body: some View {
        layout {
            content()
        }
    }
}

#Preview {
    DynamicStack {
        Text("A")
        Text("B")
    }
}


