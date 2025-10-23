// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ButtonInternal {
  struct TextButtonDecoration: ViewModifier {
    @Environment(\.controlSize) private var controlSize
    @Environment(\.isLoading) private var isLoading
    @Environment(\.isCompact) private var isCompact

    var variant: ButtonVariant

    func body(content: Content) -> some View {
      content
        .overlayPreferenceValue(BoundsPreferenceKey.self) { preferences in
          GeometryReader { geometry in
            var rect: CGRect {
              if let preferences {
                // Convert the frame of the label's title (without icon) into the local
                // coordinate system
                return geometry[preferences]
              }
              return geometry.frame(in: .local)
            }

            var offset: Double {
              variant == .label ? -2 : 4
            }

            if isLoading == false {
              Rectangle()
                .frame(width: rect.width, height: 2)
                .offset(x: rect.minX, y: rect.maxY + offset)
            }
          }
        }
    }
  }
}
