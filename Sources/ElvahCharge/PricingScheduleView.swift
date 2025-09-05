// Copyright © elvah. All rights reserved.

import SwiftUI

public struct PricingScheduleView: View {
	@StateObject private var router = ChargeBanner.Router()

	public init() {}

	public var body: some View {
		if #available(iOS 16.0, *) {
			PricingScheduleViewComponent(schedule: .mock)
				.withEnvironmentObjects()
		} else {
			EmptyView()
		}
	}
}

package extension PricingScheduleView {
	final class Router: BaseRouter {
		@Published var chargeSiteDetail: ChargeSite?
		@Published var showChargeSession = false

		package func reset() {
			chargeSiteDetail = nil
			showChargeSession = false
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	PricingScheduleView()
		.withFontRegistration()
}
