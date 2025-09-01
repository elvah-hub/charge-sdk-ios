// Copyright © elvah. All rights reserved.

import Foundation

extension ChargeSitePricingSchedule {
	static func parse(
		_ response: PricingScheduleSchema
	) throws(NetworkError.Client) -> ChargeSitePricingSchedule {
		func parseEntry(
			_ entry: PricingScheduleSchema.DailyPriceEntry?
		) throws(NetworkError.Client) -> Entry? {
			guard let entry else {
				return nil
			}

			let price = try ChargePrice.parse(entry.price)

			var trend: PriceTrend?
			if let trendRaw = entry.trend {
				switch trendRaw {
				case PriceTrend.up.rawValue: trend = .up
				case PriceTrend.down.rawValue: trend = .down
				case PriceTrend.stable.rawValue: trend = .stable
				default: throw .parsing(.keyPath(in: entry, keyPath: \.trend))
				}
			}

			return Entry(price: price, trend: trend)
		}

		let daily = try DailyPricing(
			yesterday: parseEntry(response.dailyPricing.yesterday),
			today: parseEntry(response.dailyPricing.today),
			tomorrow: parseEntry(response.dailyPricing.tomorrow)
		)

		let slots: [DiscountedTimeSlot] = try response.discountedTimeSlots.map { slot throws(NetworkError.Client) -> DiscountedTimeSlot in
			guard let from = Time(timeString: slot.from) else {
				throw .parsing(.keyPath(in: slot, keyPath: \.from))
			}
			guard let to = Time(timeString: slot.to) else {
				throw .parsing(.keyPath(in: slot, keyPath: \.to))
			}

			return try DiscountedTimeSlot(
				from: from,
				to: to,
				price: ChargePrice.parse(slot.price)
			)
		}

		return ChargeSitePricingSchedule(
			dailyPricing: daily,
			discountedTimeSlots: slots
		)
	}
}

struct PricingScheduleSchema: Decodable {
	var dailyPricing: DailyPricingSchema
	var discountedTimeSlots: [DiscountedTimeSlotSchema]

	struct DailyPricingSchema: Decodable {
		var yesterday: DailyPriceEntry?
		var today: DailyPriceEntry?
		var tomorrow: DailyPriceEntry?
	}

	struct DailyPriceEntry: Decodable {
		var price: ChargePriceSchema
		var trend: String?
	}

	struct DiscountedTimeSlotSchema: Decodable {
		var from: String
		var to: String
		var price: ChargePriceSchema
	}
}
