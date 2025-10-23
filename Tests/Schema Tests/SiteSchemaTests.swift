// Copyright © elvah. All rights reserved.

import CoreLocation
@testable import ElvahCharge
import Foundation
import Testing

/// Tests for Site schema parsing functionality.
@Suite("Site Schema Parsing Tests", .tags(.parsing))
struct SiteSchemaTests {
  @Test("Site schema parses valid JSON correctly")
  func siteValidParsing() throws {
    // Given: Valid site offer schema JSON
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
      "evses": []
    }
    """

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(validJSON, as: SiteOfferSchema.self)
    let site = try Site.parse(schema)

    // Then: Values are correctly parsed
    #expect(site.id == "SITE_001_BERLIN_MAIN")
    #expect(site.location.longitude == 13.404954)
    #expect(site.location.latitude == 52.520008)
    #expect(site.operatorName == "Shell Recharge")
    #expect(site.prevalentPowerType == .dc)
    #expect(site.availability == .available)

    // Address parsing
    let address = try #require(site.address)
    #expect(address.locality == "Berlin")
    #expect(address.postalCode == "10117")
    #expect(address.streetAddress == ["Unter den Linden 1", "Building A"])
  }

  @Test("Site schema handles optional fields correctly")
  func siteOptionalFields() throws {
    // Given: Schema with minimal required fields (optional fields missing or null)
    let minimalJSON = """
    {
      "id": "SITE_002_MINIMAL",
      "location": [4.41047, 51.03125],
      "operatorName": "Lidl",
      "prevalentPowerType": "AC",
      "address": {
        "locality": null,
        "postalCode": null,
        "streetAddress": null
      },
      "evses": []
    }
    """

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(minimalJSON, as: SiteOfferSchema.self)
    let site = try Site.parse(schema)

    // Then: Required fields are parsed, optional fields handle null values
    #expect(site.id == "SITE_002_MINIMAL")
    #expect(site.location.longitude == 4.41047)
    #expect(site.location.latitude == 51.03125)
    #expect(site.operatorName == "Lidl")
    #expect(site.prevalentPowerType == .ac)
    #expect(site.availability == .available)

    // Address with null optional fields
    let address = try #require(site.address)
    #expect(address.locality == nil)
    #expect(address.postalCode == nil)
    #expect(address.streetAddress == nil)
  }

  @Test("Site schema throws parsing error for invalid power type")
  func siteInvalidPowerType() throws {
    // Given: Schema with invalid power type
    let invalidPowerTypeJSON = """
    {
      "id": "SITE_003_INVALID",
      "location": [2.3522, 48.8566],
      "operatorName": "Total Energies",
      "prevalentPowerType": "INVALID_POWER_TYPE",
      "address": {
        "locality": "Paris",
        "postalCode": "75001"
      },
      "evses": []
    }
    """

    // When: Parsing the schema (should not throw for unknown power type)
    let schema = try SchemaTestHelpers.decodeSchema(invalidPowerTypeJSON, as: SiteOfferSchema.self)
    let site = try Site.parse(schema)

    // Then: Invalid power type defaults to AC
    #expect(site.prevalentPowerType == .ac)
    #expect(site.id == "SITE_003_INVALID")
    #expect(site.operatorName == "Total Energies")
  }

  @Test("Site schema parses all valid PowerType values")
  func siteValidPowerTypes() throws {
    let powerTypes = [
      ("AC", PowerType.ac),
      ("DC", PowerType.dc),
    ]

    for (rawValue, expectedType) in powerTypes {
      // Given: Schema with specific power type
      let jsonString = """
      {
        "id": "SITE_POWER_\(rawValue)",
        "location": [0.0, 0.0],
        "operatorName": "Test Operator",
        "prevalentPowerType": "\(rawValue)",
        "address": {
          "locality": "Test City"
        },
        "evses": []
      }
      """

      // When: Parsing the schema
      let schema = try SchemaTestHelpers.decodeSchema(jsonString, as: SiteOfferSchema.self)
      let site = try Site.parse(schema)

      // Then: Power type is correctly parsed
      #expect(site.prevalentPowerType == expectedType)
    }
  }

  @Test("Site schema handles location coordinate parsing correctly")
  func siteLocationParsing() throws {
    // Given: Schema with various coordinate formats
    let testCases = [
      ([0.0, 0.0], CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)),
      ([-122.4194, 37.7749], CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
      ([180.0, 90.0], CLLocationCoordinate2D(latitude: 90.0, longitude: 180.0)),
      ([-180.0, -90.0], CLLocationCoordinate2D(latitude: -90.0, longitude: -180.0)),
    ]

    for (index, (coordinates, expected)) in testCases.enumerated() {
      // Given: Schema with specific coordinates
      let jsonString = """
      {
        "id": "SITE_COORD_\(index)",
        "location": [\(coordinates[0]), \(coordinates[1])],
        "operatorName": "Test Operator",
        "prevalentPowerType": "AC",
        "address": {
          "locality": "Test City"
        },
        "evses": []
      }
      """

      // When: Parsing the schema
      let schema = try SchemaTestHelpers.decodeSchema(jsonString, as: SiteOfferSchema.self)
      let site = try Site.parse(schema)

      // Then: Coordinates are correctly parsed (longitude, latitude order in schema)
      #expect(site.location.latitude == expected.latitude)
      #expect(site.location.longitude == expected.longitude)
    }
  }

  @Test("Site schema handles address with all street address variations")
  func siteAddressStreetAddressVariations() throws {
    let testCases = [
      // Single street address line
      (["Main Street 123"], ["Main Street 123"]),
      // Multiple street address lines
      (["Building A", "Floor 2", "Suite 301"], ["Building A", "Floor 2", "Suite 301"]),
      // Empty array
      ([] as [String], [] as [String]),
    ]

    for (index, (streetAddressInput, expected)) in testCases.enumerated() {
      // Given: Schema with specific street address format
      let streetAddressJSON = streetAddressInput.isEmpty ? "[]" :
        "[\"\(streetAddressInput.joined(separator: "\", \""))\"]"

      let jsonString = """
      {
        "id": "SITE_ADDR_\(index)",
        "location": [0.0, 0.0],
        "operatorName": "Test Operator",
        "prevalentPowerType": "AC",
        "address": {
          "locality": "Test City",
          "postalCode": "12345",
          "streetAddress": \(streetAddressJSON)
        },
        "evses": []
      }
      """

      // When: Parsing the schema
      let schema = try SchemaTestHelpers.decodeSchema(jsonString, as: SiteOfferSchema.self)
      let site = try Site.parse(schema)

      // Then: Street address is correctly parsed
      let address = try #require(site.address)
      if expected.isEmpty {
        #expect(address.streetAddress?.isEmpty == true)
      } else {
        #expect(address.streetAddress == expected)
      }
    }
  }

  @Test("Site schema parses with empty operator name")
  func siteEmptyOperatorName() throws {
    // Given: Schema with empty operator name
    let emptyOperatorJSON = """
    {
      "id": "SITE_EMPTY_OPERATOR",
      "location": [7.4474, 46.9481],
      "operatorName": "",
      "prevalentPowerType": "DC",
      "address": {
        "locality": "Bern"
      },
      "evses": []
    }
    """

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(emptyOperatorJSON, as: SiteOfferSchema.self)
    let site = try Site.parse(schema)

    // Then: Empty operator name is preserved
    #expect(site.operatorName == "")
    #expect(site.id == "SITE_EMPTY_OPERATOR")
  }

  @Test("Site schema ensures availability is always set to available")
  func siteAvailabilityDefaultValue() throws {
    // Given: Schema (availability is not in schema, but always set in parsing)
    let jsonString = """
    {
      "id": "SITE_AVAILABILITY_TEST",
      "location": [8.5417, 47.3769],
      "operatorName": "Swisscharge",
      "prevalentPowerType": "AC",
      "address": {
        "locality": "Zurich"
      },
      "evses": []
    }
    """

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(jsonString, as: SiteOfferSchema.self)
    let site = try Site.parse(schema)

    // Then: Availability is always set to available
    #expect(site.availability == .available)
  }

  @Test("Site schema ensures opening hours is always nil")
  func siteOpeningHoursAlwaysNil() throws {
    // Given: Schema (opening hours not supported in current implementation)
    let jsonString = """
    {
      "id": "SITE_HOURS_TEST",
      "location": [14.4378, 50.0755],
      "operatorName": "CEZ",
      "prevalentPowerType": "DC",
      "address": {
        "locality": "Prague"
      },
      "evses": []
    }
    """

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(jsonString, as: SiteOfferSchema.self)
    let site = try Site.parse(schema)

    // Then: Opening hours is always nil
    #expect(site.openingHours == nil)
  }
}
