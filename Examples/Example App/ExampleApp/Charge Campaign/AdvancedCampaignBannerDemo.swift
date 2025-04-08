// Copyright © elvah. All rights reserved.

import ElvahCharge
import MapKit
import SwiftUI

struct AdvancedCampaignBannerDemo: View {
	@CampaignSource private var campaignSource
	@State private var showChargeSession = false
	@State private var campaignDetail: Campaign?

	var body: some View {
		DemoContent {
			if let $campaignSource {
				CampaignBanner(source: $campaignSource) { destination in
					switch destination {
					case let .campaignDetailPresentation(campaign):
						campaignDetail = campaign
					case .chargeSessionPresentation:
						showChargeSession = true
					}
				}
				.padding(.horizontal, 15)
			} else {
				ProgressView().id(UUID())
			}
		}
		.chargeSessionPresentation(isPresented: $showChargeSession)
		.campaignDetailPresentation(for: $campaignDetail)
		.navigationTitle("Campaign Banner (Advanced)")
		.navigationBarTitleDisplayMode(.inline)
		.animation(.default, value: campaignSource)
		.task {
			await loadCampaign()
		}
	}

	private func loadCampaign() async {
		do {
			if let campaign = try await Campaign.campaigns(in: .mock).first {
				campaignSource = .direct(campaign)
			}
		} catch {
			switch error {
			case let .network(networkError):
				print("Network Error: \(networkError.localizedDescription)")
			case .unauthorized:
				print("Error: Unauthorized")
			case .cancelled:
				break
			case let .unknown(error):
				print("Error: \(error.localizedDescription)")
			}
		}
	}
}

#Preview {
	AdvancedCampaignBannerDemo()
		.preferredColorScheme(.dark)
}
