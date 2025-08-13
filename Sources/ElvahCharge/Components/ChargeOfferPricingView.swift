// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargeOfferPricingView: View {
	var offer: ChargeOffer

	var body: some View {
		if offer.isDiscounted {
			discountedLayout
		} else {
			regularLayout
		}
	}

	@ViewBuilder private var regularLayout: some View {
		let price = offer.price.pricePerKWh
		AdaptiveHStack { isHorizontalStack in
			VStack(alignment: .leading) {
				title
				promotionLine
			}
			if isHorizontalStack {
				Spacer()
			}
			priceLabel(price: price)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	@ViewBuilder private var discountedLayout: some View {
		let price = offer.price.pricePerKWh
		let originalPrice = offer.originalPrice?.pricePerKWh
		VStack(alignment: .leading, spacing: 0) {
			AdaptiveHStack(
				horizontalAlignment: .leading,
				spacing: 0
			) { isHorizontalStack in
				title
				if isHorizontalStack {
					Spacer()
				}
				priceLabel(price: price)
			}
			AdaptiveHStack(
				horizontalAlignment: .leading,
				spacing: 0
			) { isHorizontalStack in
				promotionLine
				if isHorizontalStack {
					Spacer()
				}
				if let originalPrice {
					originalPriceLabel(price: originalPrice)
				}
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	@ViewBuilder private var title: some View {
		Text("Ad-hoc", bundle: .elvahCharge)
			.typography(.copy(size: .medium), weight: .bold)
	}

	@ViewBuilder private var promotionLine: some View {
		Text("Charge without registration", bundle: .elvahCharge)
			.typography(.copy(size: .small), weight: .regular)
	}

	@ViewBuilder private func priceLabel(price: Currency) -> some View {
		Text("From \(price.formatted())/kWh", bundle: .elvahCharge)
			.typography(.copy(size: .medium), weight: .bold)
			.layoutPriority(1)
	}

	@ViewBuilder private func originalPriceLabel(price: Currency) -> some View {
		Text("\(price.formatted())/kWh", bundle: .elvahCharge)
			.strikethrough()
			.typography(.copy(size: .small), weight: .regular)
			.layoutPriority(1)
	}
}
