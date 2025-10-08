// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package struct ButtonFoundationImage: View {
  @Environment(\.buttonIconSize) private var buttonIconSize

  private var image: Image

  package init(_ image: Image) {
    self.image = image
  }

  package var body: some View {
    image
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: buttonIconSize, height: buttonIconSize)
      .buttonVariant(.iconOnly)
  }
}
