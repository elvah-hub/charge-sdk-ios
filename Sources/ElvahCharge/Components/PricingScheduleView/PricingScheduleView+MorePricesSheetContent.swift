// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension PricingScheduleView {
	/// Lists additional prices for other charging speeds within the bottom sheet.
	struct MorePricesSheetContent: View {
		@Environment(\.dismiss) private var dismiss

		var chargeSite: ChargeSite

		package init(chargeSite: ChargeSite) {
			self.chargeSite = chargeSite
		}

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
			let groups = groupedChargeOffers

			if groups.isEmpty {
				Text("No additional charge points available", bundle: .elvahCharge)
					.typography(.copy(size: .medium), weight: .regular)
					.foregroundStyle(.secondaryContent)
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.horizontal, .S)
			} else {
				VStack(alignment: .leading, spacing: .size(.S)) {
					ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
						pricingRow(for: group)

						if index < groups.count - 1 {
							Divider()
						}
					}
				}
				.padding(.horizontal, .S)
			}
		}

		private func pricingRow(for group: PowerPricingGroup) -> some View {
			HStack(spacing: .size(.S)) {
				HStack(spacing: .size(.XXS)) {
					Image(.bolt)
					Text(group.maxPowerDisplay)
				}
				.typography(.copy(size: .large), weight: .regular)
				.foregroundStyle(.primaryContent)

				Spacer(minLength: 0)

				if let price = group.displayedPrice {
					Text("\(price.formatted()) /kWh", bundle: .elvahCharge)
						.typography(.copy(size: .large), weight: .bold)
						.monospacedDigit()
						.foregroundStyle(.primaryContent)
				}
			}
		}

		private var groupedChargeOffers: [PowerPricingGroup] {
			Dictionary(grouping: chargeSite.offers, by: { $0.chargePoint.maxPowerInKw })
				.map { key, value in
					PowerPricingGroup(maxPowerInKw: key, offers: value)
				}
				.sorted { lhs, rhs in
					lhs.maxPowerInKw < rhs.maxPowerInKw
				}
		}
	}
}

@available(iOS 16.0, *)
private extension PricingScheduleView.MorePricesSheetContent {
	struct PowerPricingGroup: Identifiable {
		var id: Double { maxPowerInKw }
		var maxPowerInKw: Double
		var offers: [ChargeOffer]

		var maxPowerDisplay: String {
			offers.first?.chargePoint.maxPowerInKWFormatted ?? maxPowerInKw.formatted(.number.precision(.fractionLength(0))) + " kW"
		}

		var displayedPrice: Currency? {
			offers.lazy.map(\.price.pricePerKWh).min()
		}
	}
}

@available(iOS 17.0, *)
#Preview("MorePricesSheetContent") {
	PricingScheduleView.MorePricesSheetContent(chargeSite: .mock)
		.withFontRegistration()
}
