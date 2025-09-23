// Copyright © elvah. All rights reserved.

import SwiftUI

/// Displays grouped pricing information for all charge points at a site.
@available(iOS 16.0, *)
package struct ChargeSitePricingInfoFeature: View {
	@Environment(\.dismiss) private var dismiss
	@StateObject private var router = ChargeSitePricingInfoFeature.Router()

	var chargeSite: ChargeSite

	package init(chargeSite: ChargeSite) {
		self.chargeSite = chargeSite
	}

	package var body: some View {
		BottomSheetComponent(title: "Base Pricing") {
			content
		} footer: {
			Button("Close", bundle: .elvahCharge) {
				dismiss()
			}
			.buttonStyle(.primary)
		}
		.onDisappear {
			router.reset()
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
				ForEach(groups) { group in
					pricingRow(for: group)

					if group != groups.last {
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

@available(iOS 16.0, *)
package extension ChargeSitePricingInfoFeature {
	final class Router: BaseRouter {
		package func reset() {}
	}
}

@available(iOS 16.0, *)
private extension ChargeSitePricingInfoFeature {
	struct PowerPricingGroup: Identifiable, Equatable {
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
#Preview("ChargeSitePricingInfoFeature") {
	ChargeSitePricingInfoFeature(chargeSite: .mock)
		.withFontRegistration()
		.preferredColorScheme(.dark)
}
