// Copyright © elvah. All rights reserved.

import SwiftUI

package extension View {
	/// Registers the SDK's default fonts during the initialization of the view.
	///
	/// - Warning: This in only meant to be used in previews. During actual runtime, the fonts must be
	/// registered by calling ``Elvah/initialize(with:).
	/// - Returns: A view that registers the SDK's fonts during its initialization.
	@MainActor func withFontRegistration() -> some View {
		FontRegistrationView {
			self
		}
	}
}

@MainActor
private struct FontRegistrationView<Content: View>: View {
	@StateObject private var helper = FontRegistrationViewHelper()
	private var content: Content

	init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	var body: some View {
		content
	}
}

@MainActor
private class FontRegistrationViewHelper: ObservableObject {
	init() {
		FontRegistration.registerFonts()
	}
}
