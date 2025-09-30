// Copyright © elvah. All rights reserved.

import Foundation

/// A pricing schedule for a charge site including daily pricing and discounted time slots.
public struct PricingSchedule: Codable, Hashable, Sendable {
	/// Daily pricing entries for yesterday, today and tomorrow.
	package var dailyPricing: Days

	/// The standard price that applies outside of discounted time slots.
	package var standardPrice: ChargePrice

	package init(dailyPricing: Days, standardPrice: ChargePrice) {
		self.dailyPricing = dailyPricing
		self.standardPrice = standardPrice
	}

	/// Price trend direction compared to the previous day.
	package enum PriceTrend: String, Codable, Hashable, Sendable {
		case up = "UP"
		case down = "DOWN"
		case stable = "STABLE"
	}

	/// Collection of daily pricing entries.
	package struct Days: Codable, Hashable, Sendable {
		/// Pricing for yesterday, if available.
		package var yesterday: DayPricing?

		/// Pricing for today, if available.
		package var today: DayPricing?

		/// Pricing for tomorrow, if available.
		package var tomorrow: DayPricing?
	}

	/// A daily pricing entry with optional trend.
	package struct DayPricing: Codable, Hashable, Sendable {
		/// The lowest price for the day.
		package var lowestPrice: ChargePrice

		/// The price trend, if provided.
		package var trend: PriceTrend?

		/// Discounted time slots for this specific day.
		package var discounts: [DiscountSlot]

		/// Returns the active discount slot at the given reference date, or nil if none is active.
		/// - Parameter referenceDate: The date to check for an active discount slot
		/// - Returns: The active discount slot, or nil if no discount is currently active
		package func activeDiscount(at referenceDate: Date) -> DiscountSlot? {
			guard let currentTime = Time(date: referenceDate) else {
				return nil
			}

			return discounts.first { slot in
				currentTime >= slot.from && currentTime < slot.to
			}
		}
	}

	/// A discounted time slot in a day.
	package struct DiscountSlot: Codable, Hashable, Sendable {
		/// Start time of the discounted period.
		package var from: Time

		/// End time of the discounted period.
		package var to: Time

		/// The discounted price applied within the time slot.
		package var price: ChargePrice
	}

	/// The three concrete days supported by a pricing schedule.
	package enum RelativeDay: CaseIterable, Sendable, Hashable, Codable {
		case yesterday
		case today
		case tomorrow
	}
}

package extension PricingSchedule {
	static var mock: PricingSchedule {
		PricingSchedule(
			dailyPricing: Days(
				yesterday: DayPricing(
					lowestPrice: .mock,
					trend: .stable,
					discounts: [
						DiscountSlot(
							from: Time(timeString: "08:00:00")!,
							to: Time(timeString: "12:00:00")!,
							price: ChargePrice(
								pricePerKWh: Currency(0.25),
								baseFee: nil,
								blockingFee: nil,
							),
						),
					],
				),
				today: DayPricing(
					lowestPrice: .mock,
					trend: nil,
					discounts: [
						DiscountSlot(
							from: Time(timeString: "8:00:00")!,
							to: Time(timeString: "15:00:00")!,
							price: ChargePrice(
								pricePerKWh: Currency(0.28),
								baseFee: nil,
								blockingFee: nil,
							),
						),
						DiscountSlot(
							from: Time(timeString: "16:00:00")!,
							to: Time(timeString: "16:30:00")!,
							price: ChargePrice(
								pricePerKWh: Currency(0.21),
								baseFee: nil,
								blockingFee: nil,
							),
						),
					],
				),
				tomorrow: DayPricing(
					lowestPrice: .mock,
					trend: .down,
					discounts: [
						DiscountSlot(
							from: Time(timeString: "07:00:00")!,
							to: Time(timeString: "08:00:00")!,
							price: ChargePrice(
								pricePerKWh: Currency(0.28),
								baseFee: nil,
								blockingFee: nil,
							),
						),
					],
				),
			),

			standardPrice: ChargePrice(
				pricePerKWh: Currency(0.52),
				baseFee: nil,
				blockingFee: nil,
			),
		)
	}
}
