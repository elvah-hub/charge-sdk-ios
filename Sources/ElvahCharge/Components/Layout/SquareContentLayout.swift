// Copyright © elvah. All rights reserved.

import SwiftUI

/// A layout that forces content into a square shape by using the larger dimension.
@available(iOS 16.0, *)
struct SquareContentLayout: Layout {
	/// Returns the size needed to display the content as a square.
	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		guard let subview = subviews.first else {
			return .zero
		}

		let squareSideLength = resolvedSquareSideLength(for: proposal, subview: subview)
		return CGSize(width: squareSideLength, height: squareSideLength)
	}

	/// Places the subview at the center of the bounds with square dimensions.
	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		guard let subview = subviews.first else {
			return
		}
		let squareSideLength = max(bounds.width, bounds.height)
		subview.place(
			at: CGPoint(x: bounds.midX, y: bounds.midY),
			anchor: .center,
			proposal: ProposedViewSize(width: squareSideLength, height: squareSideLength),
		)
	}

	/// Determines the square side length based on the subview's size preferences.
	private func resolvedSquareSideLength(for proposal: ProposedViewSize, subview: LayoutSubview) -> CGFloat {
		let proposedSize = subview.sizeThatFits(proposal)
		if let resolvedSideLength = resolvedFiniteSideLength(from: proposedSize) {
			return resolvedSideLength
		}

		let intrinsicSize = subview.sizeThatFits(.unspecified)
		if let resolvedSideLength = resolvedFiniteSideLength(from: intrinsicSize) {
			return resolvedSideLength
		}

		return 0
	}

	/// Returns a finite side length from the given size, or nil if invalid.
	private func resolvedFiniteSideLength(from size: CGSize) -> CGFloat? {
		let squareSideLength = max(size.width, size.height)
		guard squareSideLength.isFinite, squareSideLength > 0 else {
			return nil
		}
		return squareSideLength
	}
}
