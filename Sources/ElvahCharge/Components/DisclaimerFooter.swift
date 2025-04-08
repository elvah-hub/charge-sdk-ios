// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct DisclaimerFooter: View {
	var body: some View {
		HStack(spacing: Size.S.size) {
			Text("Powered by")
				.foregroundStyle(.secondaryContent)
				.typography(.copy(size: .small))
			HStack(spacing: Size.XS.size) {
				Image(.diamond)
					.foregroundStyle(.brand)
				Image(.elvahTextLogo)
			}
		}
		.dynamicTypeSize(...(.xxLarge))
	}
}

@available(iOS 16.0, *)
#Preview {
	ZStack {
		Color.canvas.ignoresSafeArea()
		DisclaimerFooter()
	}
	.withFontRegistration()
}
