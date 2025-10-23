// Copyright © elvah. All rights reserved.

import Foundation

extension PricingSchedule {
  static func parse(
    _ response: PricingScheduleSchema,
  ) throws(NetworkError.Client) -> PricingSchedule {
    func parseSlots(_ slots: [PricingScheduleSchema.TimeSlotSchema]) throws(NetworkError.Client) -> [DiscountSlot] {
      try slots.map { slot throws(NetworkError.Client) -> DiscountSlot in
        guard let from = Time(timeString: slot.from) else {
          throw .parsing(.keyPath(in: slot, keyPath: \.from))
        }

        guard let to = Time(timeString: slot.to) else {
          throw .parsing(.keyPath(in: slot, keyPath: \.to))
        }

        return try DiscountSlot(
          from: from,
          to: to,
          price: ChargePrice.parse(slot.price),
        )
      }
    }

    func parseEntry(
      _ entry: PricingScheduleSchema.DailyPriceEntry?,
    ) throws(NetworkError.Client) -> DayPricing? {
      guard let entry else {
        return nil
      }

      let lowestPrice = try ChargePrice.parse(entry.lowestPrice)

      var trend: PriceTrend?
      if let trendRaw = entry.trend {
        switch trendRaw {
        case PriceTrend.up.rawValue: trend = .up
        case PriceTrend.down.rawValue: trend = .down
        case PriceTrend.stable.rawValue: trend = .stable
        default: throw .parsing(.keyPath(in: entry, keyPath: \.trend))
        }
      }

      let slots = try parseSlots(entry.timeSlots)
      return DayPricing(lowestPrice: lowestPrice, trend: trend, discounts: slots)
    }

    let daily = try Days(
      yesterday: parseEntry(response.dailyPricing.yesterday),
      today: parseEntry(response.dailyPricing.today),
      tomorrow: parseEntry(response.dailyPricing.tomorrow),
    )

    let standardPrice = try ChargePrice.parse(response.standardPrice)

    return PricingSchedule(
      dailyPricing: daily,
      standardPrice: standardPrice,
    )
  }
}

struct PricingScheduleSchema: Decodable {
  var dailyPricing: DailyPricingSchema
  var standardPrice: ChargePriceSchema

  struct DailyPricingSchema: Decodable {
    var yesterday: DailyPriceEntry?
    var today: DailyPriceEntry?
    var tomorrow: DailyPriceEntry?
  }

  struct DailyPriceEntry: Decodable {
    var lowestPrice: ChargePriceSchema
    var trend: String?
    var timeSlots: [TimeSlotSchema]
  }

  struct TimeSlotSchema: Decodable {
    var from: String
    var to: String
    var price: ChargePriceSchema
  }
}
