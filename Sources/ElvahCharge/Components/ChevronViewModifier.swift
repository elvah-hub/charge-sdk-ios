// Copyright © elvah. All rights reserved.

import SwiftUI

/// A view modifier that adds a right-pointing chevron image.
struct ChevronViewModifier: ViewModifier {
	func body(content: Content) -> some View {
		HStack {
			content
			Spacer()
			Image(.chevronRight)
		}
	}
}

extension View {
	func withChevron() -> some View {
		modifier(ChevronViewModifier())
	}
}
