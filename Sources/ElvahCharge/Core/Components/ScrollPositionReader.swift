// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
private struct ScrollPositionReaderModifer: ViewModifier {
  @Binding var position: CGPoint
  var coordinateSpace: AnyHashable

  func body(content: Content) -> some View {
    content
      .background {
        GeometryReader { proxy in
          Color.clear
            .onAppear {
              position = proxy.frame(in: .named(coordinateSpace)).origin
            }
            .onChange(of: proxy.frame(in: .named(coordinateSpace))) { frame in
              position = frame.origin
            }
        }
      }
  }
}

@available(iOS 16.0, *)
package extension View {
  func scrollPositionReader(
    _ position: Binding<CGPoint>,
    in coordinateSpace: AnyHashable,
  ) -> some View {
    modifier(ScrollPositionReaderModifer(position: position, coordinateSpace: coordinateSpace))
  }
}
