// Copyright © elvah. All rights reserved.

import SwiftUI

/// A stateful wrapper around the pricing schedule component that computes and caches chart data.
public struct PricingScheduleView: View {
	@StateObject private var router = ChargeBanner.Router()

	/// The pricing schedule to visualize.
	public var schedule: PricingSchedule

	/// Cached chart entries per relative day, computed when `schedule` changes.
	@State private var chartEntries: [PricingScheduleChartEntry] = []

	/// Create a pricing schedule view.
	public init(schedule: PricingSchedule) {
		self.schedule = schedule
	}

	public var body: some View {
		if #available(iOS 16.0, *) {
			PricingScheduleViewComponent(chartEntries: chartEntries)
				.withEnvironmentObjects()
				.task(id: schedule) { @MainActor in
					chartEntries = schedule.chartEntries()
				}
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
	PricingScheduleView(schedule: .mock)
		.withFontRegistration()
}
