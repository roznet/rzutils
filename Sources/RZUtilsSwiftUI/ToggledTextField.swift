//  MIT License
//
//  Created on 12/03/2023 for flyfunboarding
//
//  Copyright (c) 2023 Brice Rosenzweig
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import SwiftUI

public struct ToggledTextField: View {
    @Binding public var text : String
    var title : String = ""
    @State private var isEditing: Bool = false

    public var image : Image?
    public var action: () -> Void = {}

    @ViewBuilder
    var textfield : some View {
        if self.isEditing {
            TextField(title, text: $text)
                .textFieldStyle(.roundedBorder)
                .onAppear(){
                    #if os(iOS)
                    UITextField.appearance().clearButtonMode = .whileEditing
                    #endif
                }
        }else{
            TextField(title, text: $text)
                .textFieldStyle(.plain)
                .disabled(true)
        }
    }
    public init(text: Binding<String>, image: Image? = nil, action: @escaping () -> Void = {}) {
        self._text = text
        self.image = image
        self.action = action
    }
    var icon : Image {
        if self.isEditing {
            return Image(systemName: "square.and.arrow.down")
                .renderingMode(.template)
        }else{
            return Image(systemName: "square.and.pencil")
                .renderingMode(.template)
        }
    }
    func toggle() {
        if self.isEditing {
            action()
        }
        self.isEditing.toggle()
    }
    
    @ViewBuilder
    var header : some View {
        HStack {
            if let image = image {
                image
                    .resizable()
                    .frame(width: 50.0, height: 50.0)
                    .foregroundColor(.accentColor)
                    .padding(.leading)
            }
            textfield
            Button(action: toggle){
                icon
            }.padding(.trailing)
        }
    }
   
    public var body: some View {
            header
    }
}

struct ToggleTextField_Previews: PreviewProvider {
    static var previews: some View {
        ToggledTextField(text: .constant("hello"), image: Image("FlyFunLogo"))
    }
}
