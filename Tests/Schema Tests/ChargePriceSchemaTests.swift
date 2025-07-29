// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

extension SchemaParsingTests {
	@Test("ChargePrice schema parses valid JSON correctly") func chargePriceSchemaParses() throws {
		let json = """
		{
		  "energyPricePerKWh": 0.42,
		  "baseFee": 1.50,
		  "blockingFee": {
		    "pricePerMinute": 0.25,
		    "startsAfterMinutes": 15
		  },
		  "currency": "EUR"
		}
		"""

		let schema = try decodeSchema(json, as: ChargePriceSchema.self)
		let chargePrice = try ChargePrice.parse(schema)

		#expect(chargePrice.pricePerKWh.amount == 0.42)
		#expect(chargePrice.pricePerKWh.identifier == "EUR")
		#expect(chargePrice.baseFee?.amount == 1.50)
		#expect(chargePrice.baseFee?.identifier == "EUR")
		#expect(chargePrice.blockingFee?.pricePerMinute.amount == 0.25)
		#expect(chargePrice.blockingFee?.pricePerMinute.identifier == "EUR")
		#expect(chargePrice.blockingFee?.startsAfterMinute == 15)
	}

	@Test("ChargePrice schema handles optional fields correctly")
	func chargePriceSchemaHandlesOptionalFields() throws {
		let jsonWithoutOptionals = """
		{
		  "energyPricePerKWh": 0.35,
		  "currency": "USD"
		}
		"""

		let schema = try decodeSchema(jsonWithoutOptionals, as: ChargePriceSchema.self)
		let chargePrice = try ChargePrice.parse(schema)

		#expect(chargePrice.pricePerKWh.amount == 0.35)
		#expect(chargePrice.pricePerKWh.identifier == "USD")
		#expect(chargePrice.baseFee == nil)
		#expect(chargePrice.blockingFee == nil)
	}

	@Test("ChargePrice schema handles partial blocking fee correctly")
	func chargePriceSchemaHandlesPartialBlockingFee() throws {
		let jsonWithPartialBlockingFee = """
		{
		  "energyPricePerKWh": 0.40,
		  "baseFee": 2.00,
		  "blockingFee": {
		    "pricePerMinute": 0.30
		  },
		  "currency": "GBP"
		}
		"""

		let schema = try decodeSchema(jsonWithPartialBlockingFee, as: ChargePriceSchema.self)
		let chargePrice = try ChargePrice.parse(schema)

		#expect(chargePrice.pricePerKWh.amount == 0.40)
		#expect(chargePrice.pricePerKWh.identifier == "GBP")
		#expect(chargePrice.baseFee?.amount == 2.00)
		#expect(chargePrice.baseFee?.identifier == "GBP")
		#expect(chargePrice.blockingFee?.pricePerMinute.amount == 0.30)
		#expect(chargePrice.blockingFee?.pricePerMinute.identifier == "GBP")
		#expect(chargePrice.blockingFee?.startsAfterMinute == nil)
	}

	@Test("ChargePrice schema handles different currencies correctly")
	func chargePriceSchemaHandlesDifferentCurrencies() throws {
		let currencies = ["EUR", "USD", "GBP", "SEK", "NOK", "DKK", "CHF"]

		for currency in currencies {
			let json = """
			{
			  "energyPricePerKWh": 0.50,
			  "baseFee": 1.00,
			  "currency": "\(currency)"
			}
			"""

			let schema = try decodeSchema(json, as: ChargePriceSchema.self)
			let chargePrice = try ChargePrice.parse(schema)

			#expect(chargePrice.pricePerKWh.identifier == currency)
			#expect(chargePrice.baseFee?.identifier == currency)
		}
	}
}
