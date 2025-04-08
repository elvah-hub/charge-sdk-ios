// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package enum ButtonVariant: Hashable, Sendable {
	static let `default`: Self = .text
	case text
	case label
	case iconOnly
}

@available(iOS 16.0, *)
package struct ButtonVariantPreferenceKey: PreferenceKey {
	package static let defaultValue: ButtonVariant = .default

	package static func reduce(value: inout ButtonVariant, nextValue: () -> ButtonVariant) {
		value = nextValue()
	}
}

@available(iOS 16.0, *)
package extension View {
	func buttonVariant(_ variant: ButtonVariant) -> some View {
		preference(key: ButtonVariantPreferenceKey.self, value: variant)
	}

	func readButtonVariant(variant: Binding<ButtonVariant>) -> some View {
		onPreferenceChange(ButtonVariantPreferenceKey.self) { newValue in
			variant.wrappedValue = newValue
		}
	}
}
