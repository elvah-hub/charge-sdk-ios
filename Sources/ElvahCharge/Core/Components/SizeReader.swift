// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
private struct SizeReaderModifier: ViewModifier {
  @Binding var size: CGSize

  func body(content: Content) -> some View {
    content
      .background {
        GeometryReader { proxy in
          Color.clear
            .onAppear {
              size = proxy.size
            }
            .onChange(of: proxy.size) { size in
              self.size = size
            }
        }
      }
  }
}

@available(iOS 16.0, *)
package extension View {
  func sizeReader(_ size: Binding<CGSize>) -> some View {
    modifier(SizeReaderModifier(size: size))
  }
}
