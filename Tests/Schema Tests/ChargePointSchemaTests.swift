// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

/// Tests for ChargePoint schema parsing functionality.
@Suite("ChargePoint Schema Parsing Tests", .tags(.parsing))
struct ChargePointSchemaTests {
  @Test(
    "ChargePoint schema parses valid power specification correctly",
    arguments: [("AC", PowerType.ac), ("DC", PowerType.dc)]
  ) func chargePointValidPowerSpecification(
    powerTypeString: String,
    powerType: PowerType
  ) throws {
    // Given: Valid charge offer schema with power specification
    let validJSON = """
    {
      "evseId": "EVB*P001*E001",
      "powerSpecification": {
        "type": "\(powerTypeString)",
        "maxPowerInKW": 150.0
      },
      "offer": {
        "type": "STANDARD",
        "price": {
          "energyPricePerKWh": 0.35,
          "currency": "EUR"
        },
        "expiresAt": "2024-12-31T23:59:59Z"
      }
    }
    """

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(validJSON, as: ChargeOfferSchema.self)
    let chargePoint = try ChargePoint.parse(schema)

    // Then: ChargePoint values are correctly parsed
    #expect(chargePoint.evseId == "EVB*P001*E001")
    #expect(chargePoint.physicalReference == nil)
    #expect(chargePoint.maxPowerInKw == 150.0)
    #expect(chargePoint.availability == .available)
    #expect(chargePoint.connectors == [])
    #expect(chargePoint.speed == .unknown)
    #expect(chargePoint.powerType == powerType)
  }

  @Test("ChargePoint schema handles missing power specification correctly")
  func chargePointMissingPowerSpecification() throws {
    // Given: Charge offer schema without power specification
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

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(minimalJSON, as: ChargeOfferSchema.self)
    let chargePoint = try ChargePoint.parse(schema)

    // Then: Default values are used when power specification is missing
    #expect(chargePoint.evseId == "EVB*P003*E001")
    #expect(chargePoint.maxPowerInKw == 0)
    #expect(chargePoint.powerType == nil)
  }

  @Test("ChargePoint schema handles invalid power type gracefully")
  func chargePointInvalidPowerType() throws {
    // Given: Charge offer schema with invalid power type
    let invalidPowerTypeJSON = """
    {
      "evseId": "EVB*P004*E001",
      "powerSpecification": {
        "type": "INVALID_TYPE",
        "maxPowerInKW": 50.0
      },
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

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(invalidPowerTypeJSON, as: ChargeOfferSchema.self)
    let chargePoint = try ChargePoint.parse(schema)

    // Then: Power type should be nil for invalid types
    #expect(chargePoint.evseId == "EVB*P004*E001")
    #expect(chargePoint.maxPowerInKw == 50.0)
    #expect(chargePoint.powerType == nil)
  }
}
