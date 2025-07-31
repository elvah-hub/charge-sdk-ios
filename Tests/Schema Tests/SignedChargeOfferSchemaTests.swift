// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

extension SchemaParsingTests {
	@Test("SignedChargeOffer parses valid standard offer correctly")
	func signedChargeOfferValidStandardParsing() throws {
		// Given: Valid signed charge offer schema JSON
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
		    "expiresAt": "2024-12-31T23:59:59Z",
		    "signedOffer": "signed_token_12345"
		  }
		}
		"""

		let mockSite = Site.mock

		// When: Parsing the schema
		let schema = try decodeSchema(validJSON, as: ChargeOfferSchema.self)
		let signedOffer = try SignedChargeOffer.parse(schema, in: mockSite)

		// Then: All values are correctly parsed
		#expect(signedOffer.evseId == "EVB*P001*E001")
		#expect(signedOffer.token == "signed_token_12345")
		#expect(signedOffer.validUntil == Date.from(iso8601: "2024-12-31T23:59:59Z"))
		#expect(signedOffer.offer.price.pricePerKWh.amount == 0.35)
		#expect(signedOffer.offer.price.baseFee?.amount == 2.50)
		#expect(signedOffer.offer.type.isStandard == true)
		#expect(signedOffer.offer.site.id == mockSite.id)
	}

	@Test("SignedChargeOffer parses valid campaign offer correctly")
	func signedChargeOfferValidCampaignParsing() throws {
		// Given: Valid signed campaign charge offer schema JSON
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
		    "expiresAt": "2024-12-31T23:59:59Z",
		    "signedOffer": "campaign_token_67890"
		  }
		}
		"""

		let mockSite = Site.mock

		// When: Parsing the schema
		let schema = try decodeSchema(validJSON, as: ChargeOfferSchema.self)
		let signedOffer = try SignedChargeOffer.parse(schema, in: mockSite)

		// Then: Campaign values are correctly parsed
		#expect(signedOffer.evseId == "EVB*P002*E001")
		#expect(signedOffer.token == "campaign_token_67890")
		#expect(signedOffer.validUntil == Date.from(iso8601: "2024-12-31T23:59:59Z"))
		#expect(signedOffer.offer.price.pricePerKWh.amount == 0.25)
		#expect(signedOffer.offer.originalPrice?.pricePerKWh.amount == 0.40)
		#expect(signedOffer.offer.type.isCampaign == true)
		#expect(signedOffer.offer.campaign?.endDate == Date.from(iso8601: "2024-06-30T14:30:00Z"))
		#expect(signedOffer.offer.site.id == mockSite.id)
	}

	@Test("SignedChargeOffer throws error for missing signedOffer token")
	func signedChargeOfferMissingTokenError() throws {
		// Given: Schema without signedOffer token
		let invalidJSON = """
		{
		  "evseId": "EVB*P003*E001",
		  "offer": {
		    "type": "STANDARD",
		    "price": {
		      "energyPricePerKWh": 0.30,
		      "currency": "EUR"
		    },
		    "expiresAt": "2024-12-31T23:59:59Z"
		  }
		}
		"""

		let mockSite = Site.mock

		// When/Then: Parsing should throw error for missing signedOffer field
		let schema = try decodeSchema(invalidJSON, as: ChargeOfferSchema.self)
		try expectParsingError(
			SignedChargeOffer.parse(schema, in: mockSite),
			expectedKeyPath: \ChargeOfferSchema.offer.signedOffer,
			in: schema
		)
	}

	@Test("SignedChargeOffer parseFromSiteOffer parses correctly")
	func signedChargeOfferParseFromSiteOffer() throws {
		// Given: Valid site offer schema JSON
		let siteOfferJSON = """
		{
		  "id": "site_123",
		  "location": [8.5417, 47.3769],
		  "operatorName": "elvah",
		  "prevalentPowerType": "DC",
		  "address": {
		    "locality": "Zurich",
		    "postalCode": "8001",
		    "streetAddress": ["Bahnhofstrasse 1"]
		  },
		  "evses": [
		    {
		      "evseId": "EVB*P006*E001",
		      "powerSpecification": {
		        "type": "DC",
		        "maxPowerInKW": 350.0
		      },
		      "offer": {
		        "type": "STANDARD",
		        "price": {
		          "energyPricePerKWh": 0.45,
		          "baseFee": 3.00,
		          "currency": "CHF"
		        },
		        "expiresAt": "2024-12-31T23:59:59Z",
		        "signedOffer": "site_offer_token"
		      }
		    },
		    {
		      "evseId": "EVB*P006*E002",
		      "offer": {
		        "type": "STANDARD",
		        "price": {
		          "energyPricePerKWh": 0.40,
		          "currency": "CHF"
		        },
		        "expiresAt": "2024-12-31T23:59:59Z",
		        "signedOffer": "other_token"
		      }
		    }
		  ]
		}
		"""

		let targetEvseId = "EVB*P006*E001"

		// When: Parsing from site offer
		let schema = try decodeSchema(siteOfferJSON, as: SiteOfferSchema.self)
		let signedOffer = try SignedChargeOffer.parseFromSiteOffer(schema, evseId: targetEvseId)

		// Then: Correct EVSE is parsed with site information
		#expect(signedOffer.evseId == targetEvseId)
		#expect(signedOffer.token == "site_offer_token")
		#expect(signedOffer.validUntil == Date.from(iso8601: "2024-12-31T23:59:59Z"))
		#expect(signedOffer.offer.price.pricePerKWh.amount == 0.45)
		#expect(signedOffer.offer.price.baseFee?.amount == 3.00)
		#expect(signedOffer.offer.price.pricePerKWh.identifier == "CHF")
		#expect(signedOffer.offer.chargePoint.maxPowerInKw == 350.0)
		#expect(signedOffer.offer.chargePoint.powerType == .dc)

		// Site information should be correctly parsed
		#expect(signedOffer.offer.site.id == "site_123")
		#expect(signedOffer.offer.site.operatorName == "elvah")
		#expect(signedOffer.offer.site.address?.locality == "Zurich")
		#expect(signedOffer.offer.site.address?.postalCode == "8001")
		#expect(signedOffer.offer.site.address?.streetAddress == ["Bahnhofstrasse 1"])
		#expect(signedOffer.offer.site.location.latitude == 47.3769)
		#expect(signedOffer.offer.site.location.longitude == 8.5417)
	}
}
