// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ButtonInternal {
  struct ButtonLabelStyle: LabelStyle {
    @Environment(\.controlSize) private var controlSize
    @Environment(\.invertedButtonLabel) private var invertedButtonLabel

    func makeBody(configuration: Configuration) -> some View {
      HStack(alignment: .center, spacing: spacing.size) {
        if controlSize.isSmall, invertedButtonLabel == false {
          configuration.title
          configuration.icon
        } else {
          configuration.icon
          configuration.title
        }
      }
    }

    private var spacing: Size {
      controlSize.isSmall ? .XXS : .XS
    }
  }
}
