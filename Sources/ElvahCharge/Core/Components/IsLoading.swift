// Copyright © elvah. All rights reserved.

import SwiftUI

private struct LoadingEnvironmentKey: EnvironmentKey {
	static let defaultValue = false
}

package extension EnvironmentValues {
	/// A Boolean value that indicates whether the view associated with this
	/// environment is in a loading state.
	var isLoading: Bool {
		get { self[LoadingEnvironmentKey.self] }
		set { self[LoadingEnvironmentKey.self] = newValue }
	}
}

private struct SetIsLoadingViewModifier: ViewModifier {
	@Environment(\.isEnabled) private var isEnabled

	var isLoading: Bool

	func body(content: Content) -> some View {
		content
			.environment(\.isEnabled, isLoading ? false : isEnabled)
			.environment(\.isLoading, isLoading)
	}
}

package extension View {
	/// Adds a condition that controls whether the view is in a loading state.
	///
	/// - Parameter loading: A Boolean value that determines whether the view is in a loading state.
	/// - Returns: A view that has the specified loading state.
	func loading(_ isLoading: Bool) -> some View {
		modifier(SetIsLoadingViewModifier(isLoading: isLoading))
	}
}
