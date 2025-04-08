// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct DealEndedBottomSheet: View {
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		BottomSheetComponent(title: title) {
			Text(
				"""
				The current deal has ended. Please check back later for more offers and promotions.
				""",
				bundle: .elvahCharge
			)
			.fixedSize(horizontal: false, vertical: true)
		} footer: {
			Button("Understood", bundle: .elvahCharge) {
				dismiss()
			}
			.buttonStyle(.primary)
		}
	}

	private var title: LocalizedStringKey {
		return "Deal Ended"
	}
}

@available(iOS 16.0, *)
#Preview {
	Color.canvas.ignoresSafeArea()
		.sheet(isPresented: .constant(true)) {
			DealEndedBottomSheet()
		}
		.withFontRegistration()
		.preferredColorScheme(.dark)
}
