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
					NavigationLink("Charge Campaign", value: Destination.simpleCampaignBanner)
					NavigationLink("Campaign Banner (Advanced)", value: Destination.advancedCampaignBanner)
				} footer: {
					Text(
						"See how you can integrate charge campaigns into your app and offer charge deals to your users."
					)
				}
			}
			.navigationDestination(for: Destination.self) { destination in
				switch destination {
				case .simpleCampaignBanner:
					SimpleCampaignBannerDemo()
				case .advancedCampaignBanner:
					AdvancedCampaignBannerDemo()
				case .chargeSessionObservation:
					ChargeSessionObservationDemo()
				}
			}
			.navigationTitle("Charging App")
		}
	}
}

private enum Destination: Hashable {
	case simpleCampaignBanner
	case advancedCampaignBanner
	case chargeSessionObservation
}

#Preview {
	Root()
		.preferredColorScheme(.dark)
}
