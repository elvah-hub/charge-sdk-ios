// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Core)
	import Core
#endif

public struct ChargeSiteScheduleView: View {
	@StateObject private var router = ChargeSiteScheduleView.Router()

	/// The pricing schedule to visualize.
	private var schedule: ChargeSiteSchedule

	/// Create a pricing schedule view.
	public init(schedule: ChargeSiteSchedule) {
		self.schedule = schedule
	}

	public var body: some View {
		if #available(iOS 16.0, *) {
			PricingScheduleView(schedule: schedule, router: router)
				.fullScreenCover(item: $router.chargeOfferDetail) { siteSchedule in
					ChargeOfferDetailRootFeature(site: nil, offers: siteSchedule.chargeSite.offers)
				}
				.withEnvironmentObjects()
		} else {
			EmptyView()
		}
	}
}

package extension ChargeSiteScheduleView {
	final class Router: BaseRouter {
		@Published var chargeOfferDetail: ChargeSiteSchedule?
		@Published var showChargeSession = false

		package func reset() {
			chargeOfferDetail = nil
			showChargeSession = false
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	ChargeSiteScheduleView(schedule: .mock)
		.withFontRegistration()
		.preferredColorScheme(.dark)
}
