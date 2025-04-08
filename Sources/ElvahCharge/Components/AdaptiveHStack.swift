// Copyright © elvah. All rights reserved.

import SwiftUI

/// A stack that switches between HStack and VStack based on the current dynamic type size.
@available(iOS 16.0, *)
struct AdaptiveHStack<Content: View>: View {
	@Environment(\.dynamicTypeSize) private var dynamicTypeSize

	private var horizontalAlignment: HorizontalAlignment
	private var verticalAlignment: VerticalAlignment
	private var spacing: CGFloat
	private var breakPoint: DynamicTypeSize
	private var content: (Bool) -> Content

	/// Creates an `AdaptiveStack` that adapts layout based on the dynamic type size.
	init(
		horizontalAlignment: HorizontalAlignment = .leading,
		verticalAlignment: VerticalAlignment = .center,
		spacing: CGFloat = Size.XS.size,
		breakPoint: DynamicTypeSize = .accessibility1,
		@ViewBuilder content: @escaping (_ isHorizontalStack: Bool) -> Content
	) {
		self.horizontalAlignment = horizontalAlignment
		self.verticalAlignment = verticalAlignment
		self.spacing = spacing
		self.breakPoint = breakPoint
		self.content = content
	}

	/// Creates an `AdaptiveStack` that adapts layout based on the dynamic type size.
	init(
		horizontalAlignment: HorizontalAlignment = .leading,
		verticalAlignment: VerticalAlignment = .center,
		spacing: CGFloat = Size.XS.size,
		breakPoint: DynamicTypeSize = .accessibility1,
		@ViewBuilder content: @escaping () -> Content
	) {
		self.init(
			horizontalAlignment: horizontalAlignment,
			verticalAlignment: verticalAlignment,
			spacing: spacing,
			breakPoint: breakPoint,
			content: { _ in content() }
		)
	}

	var body: some View {
		let isHorizontalStack = dynamicTypeSize < breakPoint
		let layout = isHorizontalStack
			? AnyLayout(HStackLayout(alignment: verticalAlignment, spacing: spacing))
			: AnyLayout(VStackLayout(alignment: horizontalAlignment, spacing: spacing))

		layout {
			content(isHorizontalStack)
		}
	}
}

@available(iOS 16.0, *)
#Preview("Default") {
	AdaptiveHStack { isHorizontalStack in
		Text("First")
			.padding()
			.background(Color.blue)
		Text("Second")
			.padding()
			.background(isHorizontalStack ? Color.green : Color.red)
	}
}

@available(iOS 16.0, *)
#Preview("Large Type") {
	AdaptiveHStack { isHorizontalStack in
		Text("First")
			.padding()
			.background(Color.blue)
		Text("Second")
			.padding()
			.background(isHorizontalStack ? Color.green : Color.red)
	}
	.environment(\.dynamicTypeSize, .accessibility5)
}
