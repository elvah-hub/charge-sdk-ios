// Copyright elvah. All rights reserved.

import ElvahCharge
import MapKit
import SwiftUI

struct AdvancedChargeBannerDemo: View {
	@ChargeBannerSource private var chargeBannerSource
	@State private var showChargeSession = false
	@State private var chargeSiteDetail: ChargeSite?

	var body: some View {
		DemoContent {
			if let $chargeBannerSource {
				ChargeBanner(source: $chargeBannerSource) { destination in
					switch destination {
					case let .chargeSitePresentation(chargeSite):
						chargeSiteDetail = chargeSite
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
		.chargePresentation(site: $chargeSiteDetail)
		.navigationTitle("Charge Banner (Advanced)")
		.navigationBarTitleDisplayMode(.inline)
		.animation(.default, value: chargeBannerSource)
		.task {
			await loadCampaign()
		}
	}

	private func loadCampaign() async {
		do {
			if let chargeSite = try await ChargeSite.campaigns(in: .mock).first {
				chargeBannerSource = .direct(chargeSite)
			}
		} catch {
			switch error {
			case let .network(networkError):
				print("Network Error: \(networkError.localizedDescription)")
			case .unauthorized:
				print("Error: Unauthorized")
			case .cancelled:
				break
			case let .unknown(unknownError):
				print("Error: \(unknownError.localizedDescription)")
			}
		}
	}
}

#Preview {
	AdvancedChargeBannerDemo()
		.preferredColorScheme(.dark)
}
