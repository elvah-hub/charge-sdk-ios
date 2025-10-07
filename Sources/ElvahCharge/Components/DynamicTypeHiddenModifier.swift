// Copyright © elvah. All rights reserved.

import SwiftUI

private struct DynamicTypeHiddenModifier: ViewModifier {
	@Environment(\.dynamicTypeSize) private var dynamicTypeSize

	var threshold: DynamicTypeSize

	func body(content: Content) -> some View {
		if dynamicTypeSize < threshold {
			content
		}
	}
}

extension View {
	func hiddenForLargeDynamicTypeSize(threshold: DynamicTypeSize = .accessibility1) -> some View {
		modifier(DynamicTypeHiddenModifier(threshold: threshold))
	}
}
