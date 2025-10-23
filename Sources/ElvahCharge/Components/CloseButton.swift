// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package struct CloseButton: View {
  @Environment(\.dismiss) private var dismiss

  var action: (() -> Void)?

  package init(action: (() -> Void)? = nil) {
    self.action = action
  }

  package var body: some View {
    Button {
      action?() ?? dismiss()
    } label: {
      Image(.close)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 25, height: 25)
        .foregroundStyle(.primaryContent)
    }
    .buttonStyle(.plain)
  }
}
