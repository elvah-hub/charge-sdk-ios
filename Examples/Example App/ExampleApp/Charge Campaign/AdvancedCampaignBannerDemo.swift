// Copyright © elvah. All rights reserved.

import ElvahCharge
import MapKit
import SwiftUI

struct AdvancedChargeBannerDemo: View {
	@ChargeBannerSource private var chargeBannerSource
	@State private var showChargeSession = false
	@State private var chargeSiteDetail: Campaign?

	var body: some View {
		DemoContent {
			if let $chargeBannerSource {
				ChargeBanner(source: $chargeBannerSource) { destination in
					switch destination {
					case let .chargeSiteDetailPresentation(campaign):
						chargeSiteDetail = campaign
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
		.chargeSiteDetailPresentation(for: $chargeSiteDetail)
		.navigationTitle("Campaign Banner (Advanced)")
		.navigationBarTitleDisplayMode(.inline)
		.animation(.default, value: chargeBannerSource)
		.task {
			await loadCampaign()
		}
	}

	private func loadCampaign() async {
		do {
			if let campaign = try await Campaign.campaigns(in: .mock).first {
				chargeBannerSource = .direct(campaign)
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
	AdvancedChargeBannerDemo()
		.preferredColorScheme(.dark)
}
