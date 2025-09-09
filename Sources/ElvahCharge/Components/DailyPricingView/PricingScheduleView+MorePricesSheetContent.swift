// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension PricingScheduleView {
	/// Lists additional prices for other charging speeds within the bottom sheet.
	struct MorePricesSheetContent: View {
		@Environment(\.dismiss) private var dismiss

		package var body: some View {
			BottomSheetComponent(title: "Other charge points") {
				content
			} footer: {
				Button("Close", bundle: .elvahCharge) {
					dismiss()
				}
				.buttonStyle(.primary)
			}
		}

		@ViewBuilder private var content: some View {
			VStack(alignment: .leading, spacing: Size.S.size) {
				HStack(spacing: Size.S.size) {
					HStack(spacing: Size.XXS.size) {
						Image(.bolt)
						Text("22 kW", bundle: .elvahCharge)
					}
					.typography(.copy(size: .large), weight: .regular)
					.foregroundStyle(.primaryContent)

					Spacer(minLength: 0)

					Text("\(Currency(0.35).formatted()) /kWh", bundle: .elvahCharge)
						.typography(.copy(size: .large), weight: .bold)
						.monospacedDigit()
						.foregroundStyle(.primaryContent)
				}

				Divider()

				HStack(spacing: Size.S.size) {
					HStack(spacing: Size.XXS.size) {
						Image(.bolt)
						Text("50 kW", bundle: .elvahCharge)
					}
					.typography(.copy(size: .large), weight: .regular)
					.foregroundStyle(.primaryContent)

					Spacer(minLength: 0)

					Text("\(Currency(0.49).formatted()) /kWh", bundle: .elvahCharge)
						.typography(.copy(size: .large), weight: .bold)
						.monospacedDigit()
						.foregroundStyle(.primaryContent)
				}
			}
			.padding(.horizontal, .S)
		}
	}
}

@available(iOS 17.0, *)
#Preview("MorePricesSheetContent") {
	PricingScheduleView.MorePricesSheetContent()
		.padding()
		.withFontRegistration()
}
