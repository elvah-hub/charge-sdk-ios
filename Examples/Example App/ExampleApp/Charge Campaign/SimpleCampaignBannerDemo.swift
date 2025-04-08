// Copyright © elvah. All rights reserved.

import ElvahCharge
import MapKit
import SwiftUI

struct SimpleCampaignBannerDemo: View {
	@CampaignSource private var campaignSource

	var body: some View {
		DemoContent {
			Button("Show Deals Nearby") {
				campaignSource = .remote(in: .mock)
			}
			if let $campaignSource {
				CampaignBanner(source: $campaignSource)
					.padding(.horizontal, 15)
			}
		}
		.navigationTitle("Campaign Banner")
		.navigationBarTitleDisplayMode(.inline)
		.animation(.default, value: campaignSource)
	}
}

#Preview {
	SimpleCampaignBannerDemo()
		.preferredColorScheme(.dark)
}
