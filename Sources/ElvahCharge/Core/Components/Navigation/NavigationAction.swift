// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package struct NavigationAction: Equatable {
	var id: UUID
	@Binding package var path: NavigationPath
	var onDismiss: @MainActor () -> Void

	init(id: UUID, path: Binding<NavigationPath>, onDismiss: @MainActor @escaping () -> Void) {
		self.id = id
		_path = path
		self.onDismiss = onDismiss
	}

	@MainActor package func dismiss() {
		onDismiss()
	}

	package static func == (lhs: NavigationAction, rhs: NavigationAction) -> Bool {
		lhs.id == rhs.id && lhs.path == rhs.path
	}
}

@available(iOS 16.0, *)
package extension View {
	func navigationRoot(path: Binding<NavigationPath>) -> some View {
		modifier(NavigationRootModifier(path: path))
	}
}

@available(iOS 16.0, *)
struct NavigationRootModifier: ViewModifier {
	@Environment(\.dismiss) private var dismiss
	@State private var id = UUID()

	@Binding var path: NavigationPath

	func body(content: Content) -> some View {
		content
			.environment(\.navigationRoot, .init(id: id, path: $path) { dismiss() })
	}
}

@available(iOS 16.0, *)
private struct Key: EnvironmentKey {
	nonisolated(unsafe) static let defaultValue: NavigationAction = .init(
		id: UUID(),
		path: .constant(.init()),
		onDismiss: {}
	)
}

@available(iOS 16.0, *)
package extension EnvironmentValues {
	var navigationRoot: NavigationAction {
		get { self[Key.self] }
		set { self[Key.self] = newValue }
	}
}
