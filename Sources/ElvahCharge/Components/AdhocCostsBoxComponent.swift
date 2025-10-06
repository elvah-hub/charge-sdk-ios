// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct AdhocCostsBoxComponent: View {
	let offer: ChargeOffer
	let onAction: (_ action: Action) -> Void

	var body: some View {
		VStack(spacing: .size(.M)) {
			CustomSection {
				LabeledContent {
					AdaptiveHStack(spacing: 4) {
						if let originalPrice = offer.originalPrice?.pricePerKWh {
							Text(originalPrice.formatted())
								.typography(.copy(size: .large), weight: .regular)
								.foregroundStyle(.secondaryContent)
								.strikethrough()
						}
						HStack(spacing: 0) {
							Text(verbatim: "\(offer.price.pricePerKWh.formatted())")
								.typography(.bold)
							Text("/kWh")
								.foregroundStyle(.secondaryContent)
						}
					}
				} label: {
					Text("Energy", bundle: .elvahCharge)
						.typography(.bold)
				}
				.labeledContentStyle(.adaptiveLayout)
				.typography(.copy(size: .large))
			}
			if offer.price.hasAdditionalCost {
				CustomBox {
					Text("Additional costs")
						.typography(.copy(size: .large), weight: .bold)
					if let baseFee = offer.price.baseFee {
						LabeledContent {
							Text(baseFee.formatted())
								.typography(.copy(size: .medium), weight: .bold)
						} label: {
							Text("Activation fee", bundle: .elvahCharge)
								.typography(.copy(size: .medium), weight: .bold)
						}
						.labeledContentStyle(.adaptiveLayout)
					}
					if showDivider {
						Divider()
					}
					if let blockingFee = offer.price.blockingFee {
						LabeledContent {
							HStack(spacing: 0) {
								Text(blockingFee.pricePerMinute.formatted())
								Text(verbatim: "/min")
							}
							.typography(.copy(size: .medium), weight: .bold)
						} label: {
							Text("Blocking fee", bundle: .elvahCharge)
								.typography(.copy(size: .medium), weight: .bold)
						}
						.labeledContentStyle(.adaptiveLayout)
					}
				}
			}
		}
		.typography(.copy(size: .large))
		.foregroundStyle(.primaryContent)
	}

	private var showDivider: Bool {
		offer.price.baseFee != nil && offer.price.blockingFee != nil
	}
}

@available(iOS 16.0, *)
extension AdhocCostsBoxComponent {
	enum Action {}
}

@available(iOS 16.0, *)
#Preview {
	ScrollView {
		VStack(spacing: 10) {
			AdhocCostsBoxComponent(offer: .mockAvailable) { _ in }
		}
		.padding(.horizontal)
	}
	.frame(maxWidth: .infinity, maxHeight: .infinity)
	.background(.canvas)
	.preferredColorScheme(.dark)
	.withFontRegistration()
}
