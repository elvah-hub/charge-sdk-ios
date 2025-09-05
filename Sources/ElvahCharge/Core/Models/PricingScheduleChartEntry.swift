// Copyright © elvah. All rights reserved.

import Foundation

/// A single chartable entry combining a relative day with its precomputed chart dataset.
package struct PricingScheduleChartEntry: Identifiable, Hashable, Sendable {
	/// The relative day (yesterday, today, tomorrow) represented by this entry.
	package var day: PricingSchedule.RelativeDay

	/// The chart-ready dataset for the given day.
	package var dataset: DailyPriceChartData

	/// Stable identity derived from the relative day since there is at most one entry per day.
	package var id: PricingSchedule.RelativeDay { day }

	/// Create a new chart entry.
	/// - Parameters:
	///   - day: The relative day represented by this entry.
	///   - dataset: The chart-ready dataset for that day.
	package init(day: PricingSchedule.RelativeDay, dataset: DailyPriceChartData) {
		self.day = day
		self.dataset = dataset
	}
}

package extension PricingSchedule {
	/// Convenience helper to create chart entries for the provided relative days.
	/// Uses `chartData(for:)` internally and omits missing days.
	/// - Parameter days: Relative days to generate entries for. Defaults to all cases.
	/// - Returns: Entries for the available days.
	func chartEntries(for days: [RelativeDay] = RelativeDay.allCases) -> [PricingScheduleChartEntry] {
		days.compactMap { day in
			chartData(for: day).map { PricingScheduleChartEntry(day: day, dataset: $0) }
		}
	}
}
