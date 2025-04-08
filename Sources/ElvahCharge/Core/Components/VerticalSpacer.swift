// Copyright © elvah. All rights reserved.

import SwiftUI

/// A view that defines a `Spacer` with either a fixed height or specifiable range.
@available(iOS 16.0, *)
package struct VerticalSpacer: View {
	private let minimum: Size?
	private let ideal: Size?
	private let maximum: Size?
	private let fixed: Size?

	/// Initialize with a fixed height.
	/// - Parameter size: The fixed size to use.
	package init(_ size: Size) {
		fixed = size

		minimum = nil
		ideal = nil
		maximum = nil
	}

	/// Initialize with a range of sizes to create a dynamically sizing `Spacer`.
	/// - Parameters:
	///   - minimum: The minimum size.
	///   - ideal: The ideal size.
	///   - maximum: The maximum size.
	package init(minimum: Size, ideal: Size? = nil, maximum: Size) {
		self.minimum = minimum
		self.ideal = ideal
		self.maximum = maximum

		fixed = nil
	}

	package var body: some View {
		if let fixed = fixed {
			Spacer(minLength: 0)
				.frame(height: fixed.size)
		} else {
			Spacer(minLength: 0)
				.frame(
					minHeight: minimum?.size,
					idealHeight: ideal?.size,
					maxHeight: maximum?.size
				)
		}
	}
}
