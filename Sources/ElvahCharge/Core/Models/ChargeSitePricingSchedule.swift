// Copyright © elvah. All rights reserved.

import Foundation

/// A pricing schedule for a charge site including daily pricing and discounted time slots.
package struct ChargeSitePricingSchedule: Codable, Hashable, Sendable {
	/// Daily pricing entries for yesterday, today and tomorrow.
	package var dailyPricing: DailyPricing

	/// Discounted time slots during which special prices apply.
	package var discountedTimeSlots: [DiscountedTimeSlot]

	package init(
		dailyPricing: DailyPricing,
		discountedTimeSlots: [DiscountedTimeSlot]
	) {
		self.dailyPricing = dailyPricing
		self.discountedTimeSlots = discountedTimeSlots
	}

	/// Price trend direction compared to the previous day.
	package enum PriceTrend: String, Codable, Hashable, Sendable {
		case up = "UP"
		case down = "DOWN"
		case stable = "STABLE"
	}

	/// Collection of daily pricing entries.
	package struct DailyPricing: Codable, Hashable, Sendable {
		/// Pricing for yesterday, if available.
		package var yesterday: Entry?

		/// Pricing for today, if available.
		package var today: Entry?

		/// Pricing for tomorrow, if available.
		package var tomorrow: Entry?
	}

	/// A daily pricing entry with optional trend.
	package struct Entry: Codable, Hashable, Sendable {
		/// The price for the day.
		package var price: ChargePrice

		/// The price trend, if provided.
		package var trend: PriceTrend?
	}

	/// A discounted time slot in a day.
	package struct DiscountedTimeSlot: Codable, Hashable, Sendable {
		/// Start time of the discounted period.
		package var from: Time

		/// End time of the discounted period.
		package var to: Time

		/// The discounted price applied within the time slot.
		package var price: ChargePrice
	}
}

package extension ChargeSitePricingSchedule {
	static var mock: ChargeSitePricingSchedule {
		ChargeSitePricingSchedule(
			dailyPricing: DailyPricing(
				yesterday: Entry(price: .mock, trend: .stable),
				today: Entry(price: .mock2, trend: nil),
				tomorrow: Entry(price: .mock3, trend: .down)
			),
			discountedTimeSlots: [
				DiscountedTimeSlot(
					from: Time(timeString: "10:00:00")!,
					to: Time(timeString: "15:00:00")!,
					price: ChargePrice(
						pricePerKWh: Currency(0.32),
						baseFee: nil,
						blockingFee: nil
					)
				),
			]
		)
	}
}
