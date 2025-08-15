// Copyright © elvah. All rights reserved.

import SwiftUI

private struct SafeAreaInsetsEnvironmentKey: EnvironmentKey {
	static let defaultValue: EdgeInsets = .init()
}

package extension EnvironmentValues {
	var safeAreaInsets: EdgeInsets {
		get { self[SafeAreaInsetsEnvironmentKey.self] }
		set { self[SafeAreaInsetsEnvironmentKey.self] = newValue }
	}
}

package extension View {
	/// Reads the safe area insets from the key window.
	///
	/// This cannot be done via the `defaultValue` above, because `UIApplication` is main actor
	/// isolated. You must set the environment value from inside a View's body, ideally at the root
	/// view:
	///
	/// ```swift
	/// RootView()
	///  .withSafeAreaInsets()
	/// ```
	func withSafeAreaInsets() -> some View {
		environment(\.safeAreaInsets, .determine())
	}
}

private extension EdgeInsets {
	@MainActor static func determine() -> EdgeInsets {
		(
			UIApplication
				.shared
				.connectedScenes
				.compactMap { $0 as? UIWindowScene }
				.flatMap { $0.windows }
				.last { $0.isKeyWindow }?
				.safeAreaInsets ?? .zero
		)
		.insets
	}
}

private extension UIEdgeInsets {
	var insets: EdgeInsets {
		EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
	}
}
