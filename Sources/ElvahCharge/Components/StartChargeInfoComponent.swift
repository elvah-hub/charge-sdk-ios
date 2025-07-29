// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct StartChargeInfoComponent: View {
	@Environment(\.dismiss) private var dismiss
	let chargePoint: ChargePoint

	var body: some View {
		BottomSheetComponent(title: "Charge") {
			VStack(alignment: .leading, spacing: Size.S.size) {
				Text("Start your session to unlock", bundle: .elvahCharge)
					.typography(.copy(size: .xLarge), weight: .bold)
					.fixedSize(horizontal: false, vertical: true)
				VStack(alignment: .leading, spacing: Size.XXS.size) {
					makeStep(number: "1", title: "Start your charging session to unlock the charge point")
					makeStep(number: "2", title: "Plug in your charging cable")
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.multilineTextAlignment(.leading)
		} footer: {
			Button("Close", bundle: .elvahCharge) {
				dismiss()
			}
			.buttonStyle(.primary)
		}
	}

	@ViewBuilder private func makeStep(number: String, title: LocalizedStringKey) -> some View {
		HStack(alignment: .firstTextBaseline, spacing: 8) {
			Text(number)
				.typography(.copy(size: .medium), weight: .bold)
				.padding(8)
				.background {
					Circle()
						.fill(.decorativeStroke)
				}
			Text(title, bundle: .elvahCharge)
				.typography(.copy(size: .large), weight: .regular)
				.multilineTextAlignment(.leading)
				.fixedSize(horizontal: false, vertical: true)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

@available(iOS 16.0, *)
#Preview {
	Color.canvas.ignoresSafeArea()
		.sheet(isPresented: .constant(true)) {
			StartChargeInfoComponent(chargePoint: .mockAvailable)
		}
		.withFontRegistration()
		.preferredColorScheme(.dark)
}
