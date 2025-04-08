// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package struct CustomBox<Content: View>: View {
	private var content: Content

	package init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	package var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			content
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 8)
		.background {
			RoundedRectangle(cornerRadius: 8)
				.foregroundStyle(.container)
			RoundedRectangle(cornerRadius: 8)
				.stroke(.decorativeStroke, lineWidth: 1)
		}
	}
}

@available(iOS 16.0, *)
#Preview {
	NavigationStack {
		ScrollView {
			VStack {
				CustomBox {
					Text(verbatim: "Example Text")
				}
			}
			.padding(.horizontal)
		}
	}
	.preferredColorScheme(.dark)
}
