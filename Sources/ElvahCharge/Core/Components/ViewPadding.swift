// Copyright © elvah. All rights reserved.

import SwiftUI

package extension View {
	/// Adds an equal padding amount to specific edges of this view,
	/// using `Size` enum.
	///
	/// - Parameters:
	///   - edges: The set of edges to pad for this view. The default
	///     is ``Edge/Set/all``.
	///   - size: The size of the padding.
	///
	/// - Returns: A view that's padded by the specified amount on the
	///   specified edges.
	func padding(_ edges: Edge.Set, _ size: Size) -> some View {
		padding(edges, size.size)
	}

	func padding(_ size: Size) -> some View {
		padding(.all, size.size)
	}
}
