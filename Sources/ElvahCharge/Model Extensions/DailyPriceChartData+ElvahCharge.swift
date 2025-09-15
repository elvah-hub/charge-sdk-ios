// Copyright © elvah. All rights reserved.

import SwiftUI

package extension DailyPriceChartData {
	/// Price at a point in time for this day, considering discounts.
	func price(at date: Date) -> Currency {
		for segment in discounts where date >= segment.startTime && date < segment.endTime {
			return segment.price
		}
		return basePrice
	}

	/// True when the given time falls within a discounted segment.
	func hasDiscount(at date: Date) -> Bool {
		for segment in discounts where date >= segment.startTime && date < segment.endTime {
			return true
		}
		return false
	}

	/// Returns the segment range (discount or gap) containing the given date.
	func dateRangeOfSegment(containing date: Date) -> ClosedRange<Date>? {
		if let discount = discounts.first(where: { date >= $0.startTime && date < $0.endTime }) {
			return discount.startTime ... discount.endTime
		}
		if let gap = gaps.first(where: { date >= $0.startTime && date < $0.endTime }) {
			return gap.startTime ... gap.endTime
		}
		return nil
	}
}

package extension [DailyPriceChartData.DiscountSpan] {
	func activeSpan(at reference: Date) -> DailyPriceChartData.DiscountSpan? {
		first(where: { reference >= $0.startTime && reference < $0.endTime })
	}

	func nextSpan(after reference: Date) -> DailyPriceChartData.DiscountSpan? {
		first(where: { reference >= $0.startTime })
	}
}

package extension DailyPriceChartData.DiscountSpan {
	var timeRangeText: Text {
		(startTime ... endTime).textRepresentation
	}

	var timeRangeAccessibilityText: Text {
		(startTime ... endTime).accessibilityTextRepresentation
	}
}
