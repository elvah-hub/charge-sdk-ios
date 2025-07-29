// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

extension SchemaParsingTests {
	@Test("ChargeOffer schema parses valid standard offer correctly")
	func chargeOfferValidStandardParsing() throws {
		// Given: Valid standard charge offer schema JSON
		let validJSON = """
		{
		  "evseId": "EVB*P001*E001",
		  "powerSpecification": {
		    "type": "DC",
		    "maxPowerInKW": 150.0
		  },
		  "offer": {
		    "type": "STANDARD",
		    "price": {
		      "energyPricePerKWh": 0.35,
		      "baseFee": 2.50,
		      "blockingFee": {
		        "pricePerMinute": 0.10,
		        "startsAfterMinutes": 240
		      },
		      "currency": "EUR"
		    },
		    "expiresAt": "2024-12-31T23:59:59Z"
		  }
		}
		"""

		let mockSite = Site.mock

		// When: Parsing the schema
		let schema = try decodeSchema(validJSON, as: ChargeOfferSchema.self)
		let chargeOffer = try ChargeOffer.parse(schema, in: mockSite)

		// Then: Values are correctly parsed
		#expect(chargeOffer.evseId == "EVB*P001*E001")
		#expect(chargeOffer.chargePoint.evseId == "EVB*P001*E001")
		#expect(chargeOffer.price.pricePerKWh.amount == 0.35)
		#expect(chargeOffer.price.pricePerKWh.identifier == "EUR")
		#expect(chargeOffer.price.baseFee?.amount == 2.50)
		#expect(chargeOffer.price.blockingFee?.pricePerMinute.amount == 0.10)
		#expect(chargeOffer.price.blockingFee?.startsAfterMinute == 240)
		#expect(chargeOffer.originalPrice == nil)
		#expect(chargeOffer.type.isStandard == true)
		#expect(chargeOffer.type.isCampaign == false)
		#expect(chargeOffer.site.id == mockSite.id)
	}

	@Test("ChargeOffer schema parses valid campaign offer correctly")
	func chargeOfferValidCampaignParsing() throws {
		// Given: Valid campaign charge offer schema JSON
		let validJSON = """
		{
		  "evseId": "EVB*P002*E001",
		  "powerSpecification": {
		    "type": "AC",
		    "maxPowerInKW": 22.0
		  },
		  "offer": {
		    "type": "CAMPAIGN",
		    "campaignEndsAt": "2024-06-30T14:30:00Z",
		    "price": {
		      "energyPricePerKWh": 0.25,
		      "currency": "EUR"
		    },
		    "originalPrice": {
		      "energyPricePerKWh": 0.40,
		      "baseFee": 1.00,
		      "currency": "EUR"
		    },
		    "expiresAt": "2024-12-31T23:59:59Z"
		  }
		}
		"""

		let mockSite = Site.mock

		// When: Parsing the schema
		let schema = try decodeSchema(validJSON, as: ChargeOfferSchema.self)
		let chargeOffer = try ChargeOffer.parse(schema, in: mockSite)

		// Then: Campaign values are correctly parsed
		#expect(chargeOffer.evseId == "EVB*P002*E001")
		#expect(chargeOffer.price.pricePerKWh.amount == 0.25)
		#expect(chargeOffer.originalPrice?.pricePerKWh.amount == 0.40)
		#expect(chargeOffer.originalPrice?.baseFee?.amount == 1.00)
		#expect(chargeOffer.type.isCampaign == true)
		#expect(chargeOffer.type.isStandard == false)

		// Verify campaign info
		let campaignInfo = chargeOffer.campaign
		#expect(campaignInfo != nil)
		#expect(campaignInfo?.endDate == Date.from(iso8601: "2024-06-30T14:30:00Z"))
	}

	@Test("ChargeOffer schema handles minimal required fields correctly")
	func chargeOfferMinimalFields() throws {
		// Given: Schema with minimal required fields
		let minimalJSON = """
		{
		  "evseId": "EVB*P003*E001",
		  "offer": {
		    "type": "STANDARD",
		    "price": {
		      "energyPricePerKWh": 0.30,
		      "currency": "USD"
		    },
		    "expiresAt": "2024-12-31T23:59:59Z"
		  }
		}
		"""

		let mockSite = Site.mock

		// When: Parsing the schema
		let schema = try decodeSchema(minimalJSON, as: ChargeOfferSchema.self)
		let chargeOffer = try ChargeOffer.parse(schema, in: mockSite)

		// Then: Required fields are parsed, optional fields are nil
		#expect(chargeOffer.evseId == "EVB*P003*E001")
		#expect(chargeOffer.price.pricePerKWh.amount == 0.30)
		#expect(chargeOffer.price.pricePerKWh.identifier == "USD")
		#expect(chargeOffer.price.baseFee == nil)
		#expect(chargeOffer.price.blockingFee == nil)
		#expect(chargeOffer.originalPrice == nil)
		#expect(chargeOffer.type.isStandard == true)
		#expect(chargeOffer.chargePoint.powerType == nil)
		#expect(chargeOffer.chargePoint.maxPowerInKw == 0)
	}

	@Test("ChargeOffer schema throws parsing error for invalid offer type")
	func chargeOfferInvalidOfferType() throws {
		// Given: Schema with invalid offer type
		let invalidTypeJSON = """
		{
		  "evseId": "EVB*P004*E001",
		  "offer": {
		    "type": "INVALID_TYPE",
		    "price": {
		      "energyPricePerKWh": 0.30,
		      "currency": "EUR"
		    },
		    "expiresAt": "2024-12-31T23:59:59Z"
		  }
		}
		"""

		let mockSite = Site.mock

		// When/Then: Parsing should throw a parsing error for offer type field
		let schema = try decodeSchema(invalidTypeJSON, as: ChargeOfferSchema.self)
		try expectParsingError(
			ChargeOffer.parse(schema, in: mockSite),
			expectedKeyPath: \ChargeOfferSchema.offer.type,
			in: schema
		)
	}

	@Test("ChargeOffer schema handles complex pricing structure correctly")
	func chargeOfferComplexPricing() throws {
		// Given: Schema with complex pricing including all optional fields
		let complexPricingJSON = """
		{
		  "evseId": "EVB*P009*E001",
		  "powerSpecification": {
		    "type": "DC",
		    "maxPowerInKW": 350.0
		  },
		  "offer": {
		    "type": "CAMPAIGN",
		    "campaignEndsAt": "2024-08-15T12:00:00.123Z",
		    "price": {
		      "energyPricePerKWh": 0.28,
		      "baseFee": 1.50,
		      "blockingFee": {
		        "pricePerMinute": 0.12,
		        "startsAfterMinutes": 180
		      },
		      "currency": "EUR"
		    },
		    "originalPrice": {
		      "energyPricePerKWh": 0.45,
		      "baseFee": 3.00,
		      "blockingFee": {
		        "pricePerMinute": 0.20,
		        "startsAfterMinutes": 120
		      },
		      "currency": "EUR"
		    },
		    "expiresAt": "2024-12-31T23:59:59Z"
		  }
		}
		"""

		let mockSite = Site.mock

		// When: Parsing the schema
		let schema = try decodeSchema(complexPricingJSON, as: ChargeOfferSchema.self)
		let chargeOffer = try ChargeOffer.parse(schema, in: mockSite)

		// Then: All pricing components are correctly parsed
		#expect(chargeOffer.evseId == "EVB*P009*E001")
		#expect(chargeOffer.type.isCampaign == true)

		// Current price
		#expect(chargeOffer.price.pricePerKWh.amount == 0.28)
		#expect(chargeOffer.price.baseFee?.amount == 1.50)
		#expect(chargeOffer.price.blockingFee?.pricePerMinute.amount == 0.12)
		#expect(chargeOffer.price.blockingFee?.startsAfterMinute == 180)

		// Original price
		#expect(chargeOffer.originalPrice?.pricePerKWh.amount == 0.45)
		#expect(chargeOffer.originalPrice?.baseFee?.amount == 3.00)
		#expect(chargeOffer.originalPrice?.blockingFee?.pricePerMinute.amount == 0.20)
		#expect(chargeOffer.originalPrice?.blockingFee?.startsAfterMinute == 120)

		// Campaign info with fractional seconds
		let expectedEndDate = Date.from(iso8601: "2024-08-15T12:00:00.123Z")
		#expect(chargeOffer.campaign?.endDate == expectedEndDate)

		// Power specification
		#expect(chargeOffer.chargePoint.maxPowerInKw == 350.0)
		#expect(chargeOffer.chargePoint.powerType == .dc)
	}
}
