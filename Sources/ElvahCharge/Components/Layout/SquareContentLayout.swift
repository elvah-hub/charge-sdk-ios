// Copyright © elvah. All rights reserved.

import SwiftUI

/// Centers its only child in a square whose side equals the child's
/// largest dimension, so growth stays centered.
@available(iOS 16.0, *)
struct SquareContentLayout: Layout {
  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout (),
  ) -> CGSize {
    guard let s = subviews.first else {
      return .zero
    }
    let ideal = s.sizeThatFits(proposal) // ask child for its size
    let side = max(ideal.width, ideal.height) // make it square
    return CGSize(width: side, height: side) // container's bounds
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout (),
  ) {
    guard let s = subviews.first else {
      return
    }
    let ideal = s.sizeThatFits(proposal)
    s.place(
      at: CGPoint(x: bounds.midX, y: bounds.midY),
      anchor: .center, // <- crucial bit
      proposal: ProposedViewSize(width: ideal.width, height: ideal.height),
    )
  }
}
