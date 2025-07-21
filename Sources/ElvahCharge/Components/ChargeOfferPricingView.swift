// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargeOfferPricingView: View {
	var offer: ChargeOffer

	var body: some View {
		let price = offer.price.pricePerKWh.formatted()
		let originalPrice = offer.originalPrice?.pricePerKWh.formatted()

		VStack(alignment: .leading, spacing: 0) {
			AdaptiveHStack(
				horizontalAlignment: .leading,
				spacing: 0
			) { isHorizontalStack in
				Text("Ad-hoc", bundle: .elvahCharge)
				if isHorizontalStack {
					Spacer()
				}
				Text("from \(Text("\(price)/kWh", bundle: .elvahCharge))")
			}
			.typography(.copy(size: .medium), weight: .bold)
			AdaptiveHStack(
				horizontalAlignment: .leading,
				spacing: 0
			) { isHorizontalStack in
				Text("Charge without registration", bundle: .elvahCharge)
				if isHorizontalStack {
					Spacer()
				}
				if let originalPrice {
					Text("\(originalPrice)/kWh", bundle: .elvahCharge)
						.strikethrough()
				}
			}
			.typography(.copy(size: .small))
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}
