// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ButtonStack<Content: View>: View {
  private var axis: Axis.Set
  private var content: Content

  package init(axis: Axis.Set = .vertical, @ViewBuilder content: () -> Content) {
    self.axis = axis
    self.content = content()
  }

  package var body: some View {
    let layout = axis == .vertical
      ? AnyLayout(VStackLayout(spacing: Size.S.size))
      : AnyLayout(HStackLayout(spacing: Size.S.size))
    layout {
      content
    }
  }
}
