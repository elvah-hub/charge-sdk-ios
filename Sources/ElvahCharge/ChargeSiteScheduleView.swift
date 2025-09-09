// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Core)
	import Core
#endif

public struct ChargeSiteScheduleView: View {
	@StateObject private var router = ChargeSiteScheduleView.Router()

	/// The pricing schedule to visualize.
	private var schedule: ChargeSiteSchedule

	/// Whether to hide operator details in the schedule header.
	private var isOperatorDetailsHidden = false

	/// Whether to hide the charge button.
	private var isChargeButtonHidden = false

	/// Create a pricing schedule view.
	public init(schedule: ChargeSiteSchedule) {
		self.schedule = schedule
	}

	public var body: some View {
		if #available(iOS 16.0, *) {
			PricingScheduleView(
				schedule: schedule,
				router: router,
				isOperatorDetailsHidden: isOperatorDetailsHidden,
				isChargeButtonHidden: isChargeButtonHidden
			)
			.fullScreenCover(item: $router.chargeOfferDetail) { siteSchedule in
				ChargeOfferDetailRootFeature(site: nil, offers: siteSchedule.chargeSite.offers)
			}
			.withEnvironmentObjects()
		} else {
			EmptyView()
		}
	}
}

public extension ChargeSiteScheduleView {
	/// Hides the operator details header of the pricing schedule.
	func operatorDetailsHidden(_ hide: Bool = true) -> ChargeSiteScheduleView {
		var copy = self
		copy.isOperatorDetailsHidden = hide
		return copy
	}

	/// Hides the "Charge now" button beneath the schedule.
	func chargeButtonHidden(_ hide: Bool = true) -> ChargeSiteScheduleView {
		var copy = self
		copy.isChargeButtonHidden = hide
		return copy
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
