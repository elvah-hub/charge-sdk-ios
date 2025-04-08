// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package struct CustomSectionStack<Content: View>: View {
	private var axis: Axis.Set
	private var content: Content

	package init(axis: Axis.Set = .vertical, @ViewBuilder content: () -> Content) {
		self.axis = axis
		self.content = content()
	}

	package var body: some View {
		let layout = axis == .vertical
			? AnyLayout(VStackLayout(spacing: 16))
			: AnyLayout(HStackLayout(spacing: 16))
		layout {
			content
		}
	}
}

@available(iOS 16.0, *)
#Preview {
	NavigationStack {
		ScrollView {
			CustomSectionStack {
				CustomSection {
					Text(verbatim: "Example Text")
				}
				CustomSection {
					Text(verbatim: "Example Text")
				}
			}
			.padding(.horizontal)
		}
	}
	.preferredColorScheme(.dark)
}
