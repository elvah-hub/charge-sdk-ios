// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct FooterView<ViewContent: View>: View {
	private let content: ViewContent

	init(@ViewBuilder content: @escaping () -> ViewContent) {
		self.content = content()
	}

	var body: some View {
		content
			.padding()
			.frame(maxWidth: .infinity)
			.background(.canvas)
	}
}

@available(iOS 16.0, *)
#Preview {
	VStack {
		Spacer()
		FooterView {
			Text("content-sample", bundle: .elvahCharge)
		}
	}
}
