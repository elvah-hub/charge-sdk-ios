// Copyright © elvah. All rights reserved.

import SwiftUI

struct Root: View {
	var body: some View {
		NavigationStack {
			List {
				Section {
					NavigationLink("Session Observation", value: Destination.chargeSessionObservation)
				} footer: {
					Text("See how you can observe the status of a charge session and how to present one.")
				}

				Section {
					NavigationLink("Charge Banner", value: Destination.simpleChargeBanner)
					NavigationLink("Charge Banner (Advanced)", value: Destination.advancedChargeBanner)
					NavigationLink("Charge Offer List", value: Destination.chargeOfferList)
					NavigationLink("Live Pricing", value: Destination.livePricing)
				} footer: {
					Text(
						"See how you can integrate charge offers into your app and offer charge deals to your users."
					)
				}
			}
			.navigationDestination(for: Destination.self) { destination in
				switch destination {
				case .simpleChargeBanner:
					SimpleChargeBannerDemo()
				case .advancedChargeBanner:
					AdvancedChargeBannerDemo()
				case .chargeSessionObservation:
					ChargeSessionObservationDemo()
				case .chargeOfferList:
					ChargeOfferListDemo()
				case .livePricing:
					LivePricingDemo()
				}
			}
			.navigationTitle("Charging App")
		}
	}
}

private enum Destination: Hashable {
	case simpleChargeBanner
	case advancedChargeBanner
	case chargeSessionObservation
	case chargeOfferList
	case livePricing
}

#Preview {
	Root()
		.preferredColorScheme(.dark)
}
