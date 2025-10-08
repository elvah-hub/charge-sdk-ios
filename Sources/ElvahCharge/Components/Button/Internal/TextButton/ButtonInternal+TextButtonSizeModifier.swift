// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ButtonInternal {
  struct TextButtonSizeModifier: ViewModifier {
    @Environment(\.controlSize) private var controlSize
    @Environment(\.isCompact) private var isCompact

    var variant: ButtonVariant

    func body(content: Content) -> some View {
      content
        .padding(.horizontal, horizontalPadding)
        .frame(height: height)
        .environment(\.buttonIconSize, buttonIconSize)
    }

    private var buttonIconSize: Double {
      controlSize.isSmall ? 16 : 24
    }

    private var height: Double {
      if controlSize.isSmall {
        return isCompact ? 24 : 36
      }
      return isCompact ? 32 : 48
    }

    private var verticalPadding: Size {
      isCompact ? .zero : .XS
    }

    private var horizontalPadding: Size {
      isCompact ? .zero : .XXS
    }
  }
}
