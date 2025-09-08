// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Core)
	import Core
#endif

public struct PricingScheduleView: View {
	@StateObject private var router = PricingScheduleView.Router()

	/// The pricing schedule to visualize.
	private var schedule: ChargeSiteSchedule

	/// Create a pricing schedule view.
	public init(schedule: ChargeSiteSchedule) {
		self.schedule = schedule
	}

	public var body: some View {
		if #available(iOS 16.0, *) {
			PricingScheduleViewComponent(schedule: schedule, router: router)
				.fullScreenCover(item: $router.chargeOfferDetail) { siteSchedule in
					ChargeOfferDetailRootFeature(site: nil, offers: siteSchedule.chargeSite.offers)
				}
				.withEnvironmentObjects()
		} else {
			EmptyView()
		}
	}
}

package extension PricingScheduleView {
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
	PricingScheduleView(schedule: .mock)
		.withFontRegistration()
}
