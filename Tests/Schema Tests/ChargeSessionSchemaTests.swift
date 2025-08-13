// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

/// Tests for ChargeSession schema parsing functionality.
@Suite("ChargeSession Schema Parsing Tests", .tags(.parsing))
struct ChargeSessionSchemaTests {
  @Test("ChargeSession schema parses valid JSON correctly") 
  func chargeSessionValidParsing() throws {
    // Given: Valid charge session schema JSON
    let validJSON = """
    {
      "evseId": "EVB*P001*E001",
      "status": "CHARGING",
      "consumption": 25.5,
      "duration": 1800
    }
    """

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(validJSON, as: ChargeSessionSchema.self)
    let chargeSession = try ChargeSession.parse(schema)

    // Then: Values are correctly parsed
    #expect(chargeSession.evseId == "EVB*P001*E001")
    #expect(chargeSession.status == .charging)
    #expect(chargeSession.consumption.value == 25.5)
    #expect(chargeSession.duration == 1800)
  }

  @Test("ChargeSession schema handles optional fields correctly")
  func chargeSessionOptionalFields() throws {
    // Given: Schema with minimal required fields
    let minimalJSON = """
    {
      "evseId": "EVB*P001*E001",
      "status": "STARTED"
    }
    """

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(minimalJSON, as: ChargeSessionSchema.self)
    let chargeSession = try ChargeSession.parse(schema)

    // Then: Optional fields default correctly
    #expect(chargeSession.evseId == "EVB*P001*E001")
    #expect(chargeSession.status == .started)
    #expect(chargeSession.consumption.value == 0)
    #expect(chargeSession.duration == 0)
  }

  @Test("ChargeSession schema throws parsing error for invalid status")
  func chargeSessionInvalidStatus() throws {
    // Given: Schema with invalid status
    let invalidStatusJSON = """
    {
      "evseId": "EVB*P001*E001",
      "status": "INVALID_STATUS",
      "consumption": 25.5,
      "duration": 1800
    }
    """

    // When/Then: Parsing should throw a parsing error for status field
    let schema = try SchemaTestHelpers.decodeSchema(invalidStatusJSON, as: ChargeSessionSchema.self)
    try SchemaTestHelpers.expectParsingError(
      ChargeSession.parse(schema),
      expectedKeyPath: \ChargeSessionSchema.status,
      in: schema
    )
  }

  @Test(
    "ChargeSession schema parses all valid status values",
    arguments: [
      ("START_REQUESTED", ChargeSession.Status.startRequested),
      ("START_REJECTED", .startRejected),
      ("STARTED", .started),
      ("CHARGING", .charging),
      ("STOP_REQUESTED", .stopRequested),
      ("STOP_REJECTED", .stopRejected),
      ("STOPPED", .stopped),
    ]
  ) func chargeSessionAllValidStatuses(
    statusString: String,
    expectedStatus: ChargeSession.Status
  ) throws {
    // Given: Schema with each valid status
    let json = """
    {
      "evseId": "EVB*P001*E001",
      "status": "\(statusString)"
    }
    """

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(json, as: ChargeSessionSchema.self)
    let chargeSession = try ChargeSession.parse(schema)

    // Then: Status is correctly parsed
    #expect(chargeSession.status == expectedStatus)
  }
}
