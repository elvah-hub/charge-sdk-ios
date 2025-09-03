// Copyright © elvah. All rights reserved.

import Foundation

/// Simple chart-ready data for visualizing a day's discounted pricing in Swift Charts.
///
/// x-axis: the hour within the selected day (Date values)
/// y-axis: the price per kWh (Currency.amount as Double)
package struct ChargeSitePricingChartData: Hashable, Sendable {
	/// The day the chart points represent (midnight at the current timezone).
	package var day: Date

	/// The base price (usually the day's lowest price) used as the baseline band.
	package var basePrice: Currency

	/// The points forming step segments for discounted time slots.
	/// Each slot contributes two points: the start and end time with the slot price.
	package var points: [Point]

	/// A single data point for Swift Charts.
	package struct Point: Identifiable, Hashable, Sendable {
		/// Stable identity based on time and price.
		package var id: String { "\(time.timeIntervalSince1970)-\(price.amount)" }

		/// Exact point on the x-axis.
		package var time: Date

		/// Price for this time point.
		package var price: Currency

		/// Numeric price to map to Chart's y-axis.
		package var priceValue: Double { price.amount }
	}
}

package extension ChargeSitePricingSchedule {
	/// Builds simple chart data for a specific day using the schedule's discounted time slots.
	///
	/// - Parameters:
	///   - day: The day to build chart data for (defaults to today).
	///   - calendar: Calendar used to resolve yesterday/today/tomorrow and build Date values.
	///   - timeZone: Timezone for anchoring `Time` values to concrete `Date`s.
	/// - Returns: A `ChargeSitePricingChart` containing two points per discounted slot.
	func makeChart(
		for day: Date = Date(),
		calendar: Calendar = .current,
		timeZone: TimeZone = .current
	) -> ChargeSitePricingChartData {
		var calendar = calendar
		calendar.timeZone = timeZone

		// Choose which entry applies for the given day (schedule only contains +/- 1 day around today).
		let entry: Entry? = {
			if calendar.isDateInToday(day) {
				return dailyPricing.today
			}
			if calendar.isDateInYesterday(day) {
				return dailyPricing.yesterday
			}
			if calendar.isDateInTomorrow(day) {
				return dailyPricing.tomorrow
			}
			return dailyPricing.today
		}()

		// Midnight start-of-day to anchor `Time` values.
		let startOfDay = calendar.startOfDay(for: day)

		// Map discounted slots to step points: [start, end] per slot.
		let points: [ChargeSitePricingChartData.Point] = (entry?.timeSlots ?? [])
			.flatMap { slot -> [ChargeSitePricingChartData.Point] in
				// Ensure the `Time` uses the desired timezone when creating Dates.
				var fromTime = slot.from
				var toTime = slot.to
				fromTime.timeZone = timeZone
				toTime.timeZone = timeZone

				guard let fromDate = fromTime.date(on: startOfDay),
				      var toDate = toTime.date(on: startOfDay) else {
					return []
				}

				// Handle potential overnight ranges (e.g., 22:00 -> 02:00 next day).
				if toDate <= fromDate, let advanced = calendar.date(byAdding: .day, value: 1, to: toDate) {
					toDate = advanced
				}

				let startPoint = ChargeSitePricingChartData.Point(
					time: fromDate,
					price: slot.price.pricePerKWh
				)
				let endPoint = ChargeSitePricingChartData.Point(
					time: toDate,
					price: slot.price.pricePerKWh
				)
				return [startPoint, endPoint]
			}
			.sorted(by: { $0.time < $1.time })

		let basePrice = entry?.lowestPrice.pricePerKWh ?? Currency(0)
		return ChargeSitePricingChartData(day: startOfDay, basePrice: basePrice, points: points)
	}
}
