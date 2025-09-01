// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

@Suite("PricingSchedule Schema Parsing Tests", .tags(.parsing))
struct PricingScheduleSchemaTests {
  @Test("Parses valid pricing schedule data correctly")
  func validPricingScheduleParsing() throws {
    // Given: Valid pricing schedule schema JSON (matches API 'data' payload)
    let json = """
    {
      "dailyPricing": {
        "yesterday": {
          "lowestPrice": {
            "energyPricePerKWh": 0.54,
            "baseFee": null,
            "blockingFee": null,
            "currency": "EUR"
          },
          "trend": "STABLE",
          "timeSlots": [
            {
              "from": "10:00:00",
              "to": "15:00:00",
              "price": {
                "energyPricePerKWh": 0.32,
                "baseFee": null,
                "blockingFee": null,
                "currency": "EUR"
              }
            }
          ]
        },
        "today": {
          "lowestPrice": {
            "energyPricePerKWh": 0.54,
            "baseFee": null,
            "blockingFee": null,
            "currency": "EUR"
          },
          "timeSlots": []
        },
        "tomorrow": {
          "lowestPrice": {
            "energyPricePerKWh": 0.24,
            "baseFee": null,
            "blockingFee": null,
            "currency": "EUR"
          },
          "trend": "DOWN",
          "timeSlots": []
        }
      }
    }
    """

		// When: Decoding schema and parsing to domain
		let schema = try SchemaTestHelpers.decodeSchema(json, as: PricingScheduleSchema.self)
		let schedule = try ChargeSitePricingSchedule.parse(schema)

    // Then: Daily pricing parsed
    #expect(schedule.dailyPricing.yesterday?.lowestPrice.pricePerKWh.amount == 0.54)
    #expect(schedule.dailyPricing.yesterday?.lowestPrice.pricePerKWh.identifier == "EUR")
    #expect(schedule.dailyPricing.yesterday?.trend == .stable)

    #expect(schedule.dailyPricing.today?.lowestPrice.pricePerKWh.amount == 0.54)
    #expect(schedule.dailyPricing.today?.trend == nil)

    #expect(schedule.dailyPricing.tomorrow?.lowestPrice.pricePerKWh.amount == 0.24)
    #expect(schedule.dailyPricing.tomorrow?.trend == .down)

    // Discounted slot parsed (now part of yesterday's entry)
    #expect(schedule.dailyPricing.yesterday?.timeSlots.count == 1)
    let slot = schedule.dailyPricing.yesterday!.timeSlots[0]
    #expect(slot.from.hour == 10 && slot.from.minute == 0 && slot.from.second == 0)
    #expect(slot.to.hour == 15 && slot.to.minute == 0 && slot.to.second == 0)
    #expect(slot.price.pricePerKWh.amount == 0.32)
    #expect(slot.price.pricePerKWh.identifier == "EUR")
  }

	@Test("Throws parsing error for invalid trend value")
	func invalidTrendParsing() throws {
		// Given: Schema with unsupported trend value for tomorrow
    let json = """
    {
      "dailyPricing": {
        "tomorrow": {
          "lowestPrice": {
            "energyPricePerKWh": 0.24,
            "baseFee": null,
            "blockingFee": null,
            "currency": "EUR"
          },
          "trend": "SIDEWAYS",
          "timeSlots": []
        }
      }
    }
    """

		let schema = try SchemaTestHelpers.decodeSchema(json, as: PricingScheduleSchema.self)
		let entry = schema.dailyPricing.tomorrow!

		// Then: Parsing throws a keyPath error for the trend
    try SchemaTestHelpers.expectParsingError(
      ChargeSitePricingSchedule.parse(schema),
      expectedKeyPath: \PricingScheduleSchema.DailyPriceEntry.trend,
      in: entry
    )
  }

	@Test("Throws parsing error for invalid discounted time slot")
	func invalidTimeParsing() throws {
		// Given: Schema with invalid time string in 'from'
    let json = """
    {
      "dailyPricing": {
        "today": {
          "lowestPrice": {
            "energyPricePerKWh": 0.54,
            "baseFee": null,
            "blockingFee": null,
            "currency": "EUR"
          },
          "timeSlots": [
            {
              "from": "25:00:00",
              "to": "15:00:00",
              "price": {
                "energyPricePerKWh": 0.32,
                "baseFee": null,
                "blockingFee": null,
                "currency": "EUR"
              }
            }
          ]
        }
      }
    }
    """

    let schema = try SchemaTestHelpers.decodeSchema(json, as: PricingScheduleSchema.self)
    let slot = schema.dailyPricing.today!.timeSlots[0]

    // Then: Parsing throws a keyPath error for 'from'
    try SchemaTestHelpers.expectParsingError(
      ChargeSitePricingSchedule.parse(schema),
      expectedKeyPath: \PricingScheduleSchema.TimeSlotSchema.from,
      in: slot
    )
  }
}
