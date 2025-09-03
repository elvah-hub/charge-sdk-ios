// Copyright © elvah. All rights reserved.

import Foundation

/// Chart-ready data describing a day's pricing as time segments for Swift Charts.
///
/// - x-axis: hour of the selected day represented as `Date` values
/// - y-axis: price per kWh (taken from `Currency.amount`)
public struct ChargeSitePricingChartData: Hashable, Sendable {
	/// The day the chart represents (normalized to midnight in the used timezone).
	public var day: Date

	/// The base price used for the baseline band.
	public var basePrice: Currency

	/// Discounted pricing segments with explicit start/end times and a price.
	public var discountSegments: [DiscountSegment]

	/// Non-discount segments (baseline) covering the remaining parts of the day.
	public var nonDiscountSegments: [TimeSegment]

	/// A time range with a specific discounted price.
	public struct DiscountSegment: Identifiable, Hashable, Sendable {
		/// Stable identity from start, end and price.
		public var id: String {
			"\(startTime.timeIntervalSince1970)-\(endTime.timeIntervalSince1970)-\(price.amount)"
		}

		/// Inclusive start of the discounted range.
		public var startTime: Date

		/// Exclusive end of the discounted range.
		public var endTime: Date

		/// Discounted price applied in the time range.
		public var price: Currency

		/// Numeric value helper for Swift Charts axes.
		public var priceValue: Double { price.amount }
	}

	/// A simple time range used for baseline (non-discount) visualization.
	public struct TimeSegment: Identifiable, Hashable, Sendable {
		/// Stable identity from start and end.
		public var id: String {
			"\(startTime.timeIntervalSince1970)-\(endTime.timeIntervalSince1970)"
		}

		/// Inclusive start of the range.
		public var startTime: Date

		/// Exclusive end of the range.
		public var endTime: Date
	}
}

package extension ChargeSitePricingSchedule {
	/// Builds chart data for a specific day using the schedule's discounted slots as segments.
	///
	/// - Parameters:
	///   - day: The day to build chart data for (defaults to today).
	///   - calendar: Calendar used to resolve the day and build Date values.
	///   - timeZone: Timezone for anchoring `Time` values to concrete `Date`s.
	/// - Returns: A `ChargeSitePricingChartData` with precomputed segments.
	func makeChart(
		for day: Date = Date(),
		calendar: Calendar = .current,
		timeZone: TimeZone = .current
	) -> ChargeSitePricingChartData {
		var calendar = calendar
		calendar.timeZone = timeZone

		// Select the appropriate entry for the given day.
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

		// Midnight boundaries used both for clipping and x-domain in the chart.
		let startOfDay = calendar.startOfDay(for: day)
		let endOfDay = calendar.date(byAdding: .hour, value: 24, to: startOfDay) ?? startOfDay
		let fullDay = startOfDay ... endOfDay

		// Map discounted time slots to concrete date segments, handling overnight spans
		// and clipping to the selected day.
		let discountSegments: [ChargeSitePricingChartData.DiscountSegment] = (entry?.timeSlots ?? [])
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

				return ChargeSitePricingChartData.DiscountSegment(
					startTime: clippedStart,
					endTime: clippedEnd,
					price: slot.price.pricePerKWh
				)
			}
			.sorted(by: { $0.startTime < $1.startTime })

		// Compute baseline (non-discount) segments as the gaps across the full day.
		var nonDiscount: [ChargeSitePricingChartData.TimeSegment] = []
		var cursor = fullDay.lowerBound
		for seg in discountSegments {
			if cursor < seg.startTime {
				nonDiscount.append(.init(startTime: cursor, endTime: seg.startTime))
			}
			cursor = max(cursor, seg.endTime)
		}
		if cursor < fullDay.upperBound {
			nonDiscount.append(.init(startTime: cursor, endTime: fullDay.upperBound))
		}

		let basePrice = entry?.lowestPrice.pricePerKWh ?? Currency(0)
		return ChargeSitePricingChartData(
			day: startOfDay,
			basePrice: basePrice,
			discountSegments: discountSegments,
			nonDiscountSegments: nonDiscount
		)
	}
}
