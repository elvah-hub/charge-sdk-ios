// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct AdaptiveLabeledContentStyle: LabeledContentStyle {
	@Environment(\.dynamicTypeSize) private var dynamicTypeSize
	var breakPoint: DynamicTypeSize

	init(breakPoint: DynamicTypeSize = .accessibility1) {
		self.breakPoint = breakPoint
	}

	func makeBody(configuration: Configuration) -> some View {
		if dynamicTypeSize >= breakPoint {
			VStack(alignment: .leading, spacing: Size.XS.size) {
				configuration.label
				configuration.content
			}
		} else {
			HStack {
				configuration.label
				Spacer()
				configuration.content
			}
		}
	}
}

@available(iOS 16.0, *)
extension LabeledContentStyle where Self == AdaptiveLabeledContentStyle {
	/// Returns an adaptive layout style for `LabeledContent` that switches between HStack and VStack
	/// based on the environment's dynamic type size breakpoint.
	static func adaptiveLayout(breakPoint: DynamicTypeSize = .accessibility1) -> Self {
		AdaptiveLabeledContentStyle(breakPoint: breakPoint)
	}

	/// Returns an adaptive layout style for `LabeledContent` that switches between HStack and VStack
	/// when the environment's dynamic type size reaches `.accessibility1`.
	static var adaptiveLayout: Self {
		AdaptiveLabeledContentStyle()
	}
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview {
	LabeledContent {
		Text("Content")
	} label: {
		Text("Label")
	}
	.labeledContentStyle(.adaptiveLayout)
	.padding()
	.preferredColorScheme(.dark)
}
