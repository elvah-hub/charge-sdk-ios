// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

/// Tests for ChargeSite schema parsing functionality.
@Suite("ChargeSite Schema Parsing Tests", .tags(.parsing))
struct ChargeSiteSchemaTests {
	@Test("ChargeSite schema parses valid JSON correctly")
	func chargeSiteValidParsing() throws {
		// Given: Valid site offer schema JSON with charge offers
		let validJSON = """
		{
		  "id": "SITE_001_BERLIN_MAIN",
		  "location": [13.404954, 52.520008],
		  "operatorName": "Shell Recharge",
		  "prevalentPowerType": "DC",
		  "address": {
		    "locality": "Berlin",
		    "postalCode": "10117",
		    "streetAddress": ["Unter den Linden 1", "Building A"]
		  },
		  "evses": [
		    {
		      "evseId": "EVB*P001*E001",
		      "availability": "AVAILABLE",
		      "powerSpecification": {
		        "type": "DC",
		        "maxPowerInKW": 150.0
		      },
		      "offer": {
		        "type": "STANDARD",
		        "price": {
		          "energyPricePerKWh": 0.35,
		          "baseFee": 2.50,
		          "currency": "EUR"
		        },
		        "expiresAt": "2024-12-31T23:59:59Z"
		      }
		    }
		  ]
		}
		"""

		// When: Parsing the schema
		let schema = try SchemaTestHelpers.decodeSchema(validJSON, as: SiteOfferSchema.self)
		let chargeSite = try ChargeSite.parse(schema)

		// Then: ChargeSite values are correctly parsed
		#expect(chargeSite.id == "SITE_001_BERLIN_MAIN")
		#expect(chargeSite.location.longitude == 13.404954)
		#expect(chargeSite.location.latitude == 52.520008)
		#expect(chargeSite.operatorName == "Shell Recharge")
		#expect(chargeSite.prevalentPowerType == .dc)
		#expect(chargeSite.availability == .available)

		// Verify address parsing
		let address = try #require(chargeSite.address)
		#expect(address.locality == "Berlin")
		#expect(address.postalCode == "10117")
		#expect(address.streetAddress == ["Unter den Linden 1", "Building A"])

		// Verify offers are parsed
		#expect(chargeSite.offers.count == 1)
		let offer = try #require(chargeSite.offers.first)
		#expect(offer.evseId == "EVB*P001*E001")
		#expect(offer.price.pricePerKWh.amount == 0.35)
		#expect(offer.chargePoint.physicalReference == nil)
	}

	@Test("ChargeSite schema handles empty charge offers correctly")
	func chargeSiteEmptyOffers() throws {
		// Given: Valid site schema with no charge offers
		let emptyOffersJSON = """
		{
		  "id": "SITE_002_NO_OFFERS",
		  "location": [4.41047, 51.03125],
		  "operatorName": "Lidl",
		  "prevalentPowerType": "AC",
		  "address": {
		    "locality": "Utrecht",
		    "postalCode": "3500"
		  },
		  "evses": []
		}
		"""

		// When: Parsing the schema
		let schema = try SchemaTestHelpers.decodeSchema(emptyOffersJSON, as: SiteOfferSchema.self)
		let chargeSite = try ChargeSite.parse(schema)

		// Then: ChargeSite is created with empty offers array
		#expect(chargeSite.id == "SITE_002_NO_OFFERS")
		#expect(chargeSite.operatorName == "Lidl")
		#expect(chargeSite.offers.isEmpty)
		#expect(chargeSite.cheapestOffer == nil)
	}

	@Test("ChargeSite schema handles multiple charge offers correctly")
	func chargeSiteMultipleOffers() throws {
		// Given: Valid site schema with multiple charge offers
		let multipleOffersJSON = """
		{
		  "id": "SITE_003_MULTIPLE",
		  "location": [2.3522, 48.8566],
		  "operatorName": "Total Energies",
		  "prevalentPowerType": "DC",
		  "address": {
		    "locality": "Paris",
		    "postalCode": "75001"
		  },
		  "evses": [
		    {
		      "evseId": "EVB*P003*E001",
		      "availability": "AVAILABLE",
		      "powerSpecification": {
		        "type": "DC",
		        "maxPowerInKW": 50.0
		      },
		      "offer": {
		        "type": "STANDARD",
		        "price": {
		          "energyPricePerKWh": 0.40,
		          "baseFee": 1.50,
		          "currency": "EUR"
		        },
		        "expiresAt": "2024-12-31T23:59:59Z"
		      }
		    },
		    {
		      "evseId": "EVB*P003*E002",
		      "availability": "UNAVAILABLE",
		      "powerSpecification": {
		        "type": "DC",
		        "maxPowerInKW": 150.0
		      },
		      "offer": {
		        "type": "STANDARD",
		        "price": {
		          "energyPricePerKWh": 0.45,
		          "baseFee": 2.00,
		          "currency": "EUR"
		        },
		        "expiresAt": "2024-12-31T23:59:59Z"
		      }
		    }
		  ]
		}
		"""

		// When: Parsing the schema
		let schema = try SchemaTestHelpers.decodeSchema(multipleOffersJSON, as: SiteOfferSchema.self)
		let chargeSite = try ChargeSite.parse(schema)

		// Then: All offers are parsed correctly
		#expect(chargeSite.id == "SITE_003_MULTIPLE")
		#expect(chargeSite.offers.count == 2)

		let firstOffer = chargeSite.offers[0]
		let secondOffer = chargeSite.offers[1]

		#expect(firstOffer.evseId == "EVB*P003*E001")
		#expect(firstOffer.price.pricePerKWh.amount == 0.40)
		#expect(firstOffer.chargePoint.physicalReference == "1")
		#expect(secondOffer.evseId == "EVB*P003*E002")
		#expect(secondOffer.price.pricePerKWh.amount == 0.45)
		#expect(secondOffer.chargePoint.physicalReference == "2")
	}

	@Test("ChargeSite schema throws parsing error for invalid site data")
	func chargeSiteInvalidSiteData() throws {
		// Given: Schema with invalid location data (missing latitude)
		let invalidLocationJSON = """
		{
		  "id": "SITE_004_INVALID",
		  "location": [999.0],
		  "operatorName": "Test Operator",
		  "prevalentPowerType": "AC",
		  "address": {
		    "locality": "Test City"
		  },
		  "evses": []
		}
		"""

		// When: Parsing the schema should fail due to location array having only one element
		let schema = try SchemaTestHelpers.decodeSchema(invalidLocationJSON, as: SiteOfferSchema.self)

		// Then: Should throw parsing error (ChargeSite wraps all parsing errors as "site" field)
		#expect(throws: NetworkError.Client.self) {
			try ChargeSite.parse(schema)
		}
	}

	@Test("ChargeSite schema throws parsing error for invalid charge offer")
	func chargeSiteInvalidChargeOffer() throws {
		// Given: Schema with invalid charge offer data
		let invalidOfferJSON = """
		{
		  "id": "SITE_005_INVALID_OFFER",
		  "location": [7.4474, 46.9481],
		  "operatorName": "Test Operator",
		  "prevalentPowerType": "DC",
		  "address": {
		    "locality": "Bern"
		  },
		  "evses": [
		    {
		      "evseId": "",
		      "availability": "OUT_OF_SERVICE",
		      "powerSpecification": {
		        "type": "INVALID_TYPE",
		        "maxPowerInKW": -50.0
		      },
		      "offer": {
		        "type": "INVALID_OFFER_TYPE",
		        "price": {
		          "energyPricePerKWh": -0.35,
		          "currency": "INVALID_CURRENCY"
		        },
		        "expiresAt": "invalid-date"
		      }
		    }
		  ]
		}
		"""

		// When: Parsing the schema
		let schema = try SchemaTestHelpers.decodeSchema(invalidOfferJSON, as: SiteOfferSchema.self)

		// Then: Should throw parsing error for site field (which encompasses charge offer parsing)
		#expect(throws: NetworkError.Client.self) {
			try ChargeSite.parse(schema)
		}
	}

	@Test("ChargeSite schema preserves site properties via dynamic member lookup")
	func chargeSiteDynamicMemberLookup() throws {
		// Given: Valid site offer schema
		let validJSON = """
		{
		  "id": "SITE_006_DYNAMIC",
		  "location": [8.5417, 47.3769],
		  "operatorName": "Swisscharge",
		  "prevalentPowerType": "AC",
		  "address": {
		    "locality": "Zurich",
		    "postalCode": "8001",
		    "streetAddress": ["Bahnhofstrasse 1"]
		  },
		  "evses": []
		}
		"""

		// When: Parsing the schema
		let schema = try SchemaTestHelpers.decodeSchema(validJSON, as: SiteOfferSchema.self)
		let chargeSite = try ChargeSite.parse(schema)

		// Then: Site properties are accessible via dynamic member lookup
		#expect(chargeSite.id == "SITE_006_DYNAMIC")
		#expect(chargeSite.location.latitude == 47.3769)
		#expect(chargeSite.location.longitude == 8.5417)
		#expect(chargeSite.operatorName == "Swisscharge")
		#expect(chargeSite.prevalentPowerType == .ac)
		#expect(chargeSite.availability == .available)
		#expect(chargeSite.openingHours == nil)

		// Address properties
		let address = try #require(chargeSite.address)
		#expect(address.locality == "Zurich")
		#expect(address.postalCode == "8001")
		#expect(address.streetAddress == ["Bahnhofstrasse 1"])
	}
}
