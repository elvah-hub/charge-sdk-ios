// Copyright © elvah. All rights reserved.

import SwiftUI

struct DemoContent<Content: View>: View {
  @ViewBuilder var content: Content

  var body: some View {
    ScrollView {
      VStack(spacing: 15) {
        box(height: 40)
        content
        box(height: 100)
        box(height: 200)
        box(height: 150)
      }
    }
  }

  @ViewBuilder private func box(height: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: 10)
      .foregroundStyle(.background.secondary)
      .padding(.horizontal, 15)
      .frame(height: height)
  }
}
