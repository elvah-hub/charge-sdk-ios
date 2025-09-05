// Copyright © elvah. All rights reserved.

import Foundation

@available(iOS 16.0, *)
package extension PricingScheduleViewComponent {
	/// Shared pricing/time computations.
	enum PricingComputation {
		/// Full day domain from midnight to midnight + 24h for consistent x-axis.
		static func fullDayDomain(for day: Date) -> ClosedRange<Date> {
			let calendar = Calendar.current
			let start = calendar.startOfDay(for: day)
			let end = calendar.date(byAdding: .hour, value: 24, to: start) ?? start
			return start ... end
		}

		/// Price at a point in time for this day, considering discounts.
		static func currentPrice(at date: Date, in dataset: DailyPriceChartData) -> Double {
			for segment in dataset.discounts where date >= segment.startTime && date < segment.endTime {
				return segment.price.amount
			}
			return dataset.basePrice.amount
		}

		/// True when the given time falls within a discounted segment.
		static func isDiscounted(at date: Date, in dataset: DailyPriceChartData) -> Bool {
			for segment in dataset.discounts where date >= segment.startTime && date < segment.endTime {
				return true
			}
			return false
		}

		/// Returns the segment range (discount or gap) containing the given date.
		static func segmentRange(containing date: Date, in dataset: DailyPriceChartData) -> ClosedRange<Date>? {
			if let discount = dataset.discounts.first(where: { date >= $0.startTime && date < $0.endTime }) {
				return discount.startTime ... discount.endTime
			}
			if let gap = dataset.gaps.first(where: { date >= $0.startTime && date < $0.endTime }) {
				return gap.startTime ... gap.endTime
			}
			return nil
		}
	}
}
