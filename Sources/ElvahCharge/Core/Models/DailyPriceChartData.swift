// Copyright © elvah. All rights reserved.

import Foundation

/// Chart-ready data describing a day's pricing as time segments for Swift Charts.
///
/// - x-axis: hour of the selected day represented as `Date` values
/// - y-axis: price per kWh (taken from `Currency.amount`)
package struct DailyPriceChartData: Hashable, Sendable, Codable {
	/// The day the chart represents (normalized to midnight in the used timezone).
	package var day: Date

	/// The base price used for the baseline band.
	package var basePrice: Currency

	/// Discounted pricing segments with explicit start/end times and a price.
	package var discounts: [DiscountSpan]
	/// Non-discount segments (baseline) covering the remaining parts of the day.

	package var gaps: [GapSpan]

	/// A time range with a specific discounted price.
	package struct DiscountSpan: Identifiable, Hashable, Sendable, Codable {
		/// Stable identity from start, end and price.
		package var id: String {
			"\(startTime.timeIntervalSince1970)-\(endTime.timeIntervalSince1970)-\(price.amount)"
		}

		/// Inclusive start of the discounted range.
		package var startTime: Date

		/// Exclusive end of the discounted range.
		package var endTime: Date

		/// Discounted price applied in the time range.
		package var price: Currency

		/// Numeric value helper for Swift Charts axes.
		package var priceValue: Double { price.amount }
	}

	/// A simple time range used for baseline (non-discount) visualization.
	package struct GapSpan: Identifiable, Hashable, Sendable, Codable {
		/// Stable identity from start and end.
		package var id: String {
			"\(startTime.timeIntervalSince1970)-\(endTime.timeIntervalSince1970)"
		}

		/// Inclusive start of the range.
		package var startTime: Date

		/// Exclusive end of the range.
		package var endTime: Date
	}
}

package extension PricingSchedule {
	/// Chart data for multiple days. Defaults to all supported days in order, omitting any missing entries.
	///
	/// - Parameters:
	///   - days: The days to generate chart data for. Defaults to `[.yesterday, .today, .tomorrow]`.
	///   - calendar: Calendar used to anchor the days to concrete dates.
	///   - timeZone: Timezone for converting `Time` into `Date` values.
	/// - Returns: Array of chart data for the requested days that exist in the schedule.
	func chartData(
		for days: [RelativeDay] = RelativeDay.allCases,
		calendar: Calendar = .current,
		timeZone: TimeZone = .current,
	) -> [DailyPriceChartData] {
		days.compactMap { day in
			chartData(for: day, calendar: calendar, timeZone: timeZone)
		}
	}

	/// Chart data for a specific schedule day using discounted slots as segments.
	///
	/// - Parameters:
	///   - day: One of `.yesterday`, `.today`, `.tomorrow`.
	///   - calendar: Calendar used to anchor the day to a concrete date.
	///   - timeZone: Timezone for converting `Time` into `Date` values.
	/// - Returns: Chart data if the requested day exists; otherwise `nil`.
	func chartData(
		for day: RelativeDay,
		calendar: Calendar = .current,
		timeZone: TimeZone = .current,
	) -> DailyPriceChartData? {
		var calendar = calendar
		calendar.timeZone = timeZone

		// Resolve entry and the day's midnight from the current time.
		let now = Date()
		let baseMidnight = calendar.startOfDay(for: now)
		let entry: DayPricing?
		let startOfDay: Date

		switch day {
		case .yesterday:
			entry = dailyPricing.yesterday
			startOfDay = calendar.date(byAdding: .day, value: -1, to: baseMidnight) ?? baseMidnight
		case .today:
			entry = dailyPricing.today
			startOfDay = baseMidnight
		case .tomorrow:
			entry = dailyPricing.tomorrow
			startOfDay = calendar.date(byAdding: .day, value: 1, to: baseMidnight) ?? baseMidnight
		}
		guard let entry else {
			return nil
		}

		// Midnight boundaries used both for clipping and x-domain in the chart.
		let endOfDay = calendar.date(byAdding: .hour, value: 24, to: startOfDay) ?? startOfDay
		let fullDay = startOfDay ... endOfDay

		// Map discounted time slots to concrete date segments, handling overnight spans
		// and clipping to the selected day.
		let discountSegments: [DailyPriceChartData.DiscountSpan] = entry.discounts
			.compactMap { slot in
				var fromTime = slot.from
				var toTime = slot.to
				fromTime.timeZone = timeZone
				toTime.timeZone = timeZone

				guard let rawStart = fromTime.date(on: startOfDay),
				      var rawEnd = toTime.date(on: startOfDay) else {
					return nil
				}

				// Handle overnight ranges (e.g., 22:00 -> 02:00 next day).
				if rawEnd <= rawStart,
				   let advanced = calendar.date(byAdding: .day, value: 1, to: rawEnd) {
					rawEnd = advanced
				}

				// Clip to the day's domain.
				let clippedStart = max(rawStart, fullDay.lowerBound)
				let clippedEnd = min(rawEnd, fullDay.upperBound)
				guard clippedStart < clippedEnd else {
					return nil
				}

				return DailyPriceChartData.DiscountSpan(
					startTime: clippedStart,
					endTime: clippedEnd,
					price: slot.price.pricePerKWh,
				)
			}
			.sorted(by: { $0.startTime < $1.startTime })

		// Compute baseline (non-discount) segments as the gaps across the full day.
		var nonDiscount: [DailyPriceChartData.GapSpan] = []
		var cursor = fullDay.lowerBound

		for segment in discountSegments {
			if cursor < segment.startTime {
				nonDiscount.append(.init(startTime: cursor, endTime: segment.startTime))
			}
			cursor = max(cursor, segment.endTime)
		}

		if cursor < fullDay.upperBound {
			nonDiscount.append(.init(startTime: cursor, endTime: fullDay.upperBound))
		}

		let basePrice = standardPrice.pricePerKWh
		return DailyPriceChartData(
			day: startOfDay,
			basePrice: basePrice,
			discounts: discountSegments,
			gaps: nonDiscount,
		)
	}
}
