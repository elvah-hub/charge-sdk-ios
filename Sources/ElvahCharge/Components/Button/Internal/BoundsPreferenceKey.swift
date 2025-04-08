// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct BoundsPreferenceKey: PreferenceKey {
	typealias Value = Anchor<CGRect>?

	static let defaultValue: Value = nil

	static func reduce(
		value: inout Value,
		nextValue: () -> Value
	) {
		value = nextValue() ?? value
	}
}
