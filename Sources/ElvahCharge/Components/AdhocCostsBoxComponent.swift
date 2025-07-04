// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct AdhocCostsBoxComponent: View {
	let offer: ChargeOffer
	let onAction: (_ action: Action) -> Void

	var body: some View {
		Group {
			CustomSection {
				LabeledContent {
					HStack {
						HStack(spacing: 0) {
							Text(verbatim: "\(offer.price.pricePerKWh.formatted())")
								.typography(.bold)
							Text(" /kWh", bundle: .elvahCharge)
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
		}
		.typography(.copy(size: .large))
		.foregroundStyle(.primaryContent)
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
