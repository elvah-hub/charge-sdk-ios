// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

/// Tests for PaymentSummary schema parsing functionality.
@Suite("PaymentSummary Schema Parsing Tests", .tags(.parsing))
struct PaymentSummarySchemaTests {
  @Test("PaymentSummary schema parses valid complete data correctly")
  func paymentSummaryValidCompleteParsing() throws {
    // Given: Valid payment summary schema JSON
    let validJSON = """
    {
      "consumedKWh": 45.75,
      "sessionStartedAt": "2024-03-15T10:30:00Z",
      "sessionEndedAt": "2024-03-15T11:15:30Z",
      "totalCost": {
        "amount": 2850,
        "currency": "EUR"
      }
    }
    """

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(validJSON, as: PaymentSummarySchema.self)
    let paymentSummary = try PaymentSummary.parse(schema)

    // Then: All values are correctly parsed
    #expect(paymentSummary.consumedKWh.value == 45.75)
    #expect(paymentSummary.totalCost.amount == 28.50) // 2850 / 100
    #expect(paymentSummary.totalCost.identifier == "EUR")

    // Verify dates are parsed correctly
    let expectedStartDate = Date.from(iso8601: "2024-03-15T10:30:00Z")!
    let expectedEndDate = Date.from(iso8601: "2024-03-15T11:15:30Z")!
    #expect(paymentSummary.sessionStartedAt == expectedStartDate)
    #expect(paymentSummary.sessionEndedAt == expectedEndDate)
  }

  @Test("PaymentSummary schema throws parsing error for invalid date")
  func paymentSummaryInvalidSessionStartedAt() throws {
    // Given: Schema with invalid sessionStartedAt date format
    let invalidStartDateJSON = """
    {
      "consumedKWh": 30.0,
      "sessionStartedAt": "invalid-date-format",
      "sessionEndedAt": "2024-03-15T11:15:30Z",
      "totalCost": {
        "amount": 1500,
        "currency": "EUR"
      }
    }
    """

    // When: Attempting to parse the schema
    let schema = try SchemaTestHelpers.decodeSchema(invalidStartDateJSON, as: PaymentSummarySchema.self)

    // Then: A parsing error is thrown for sessionStartedAt
    try SchemaTestHelpers.expectParsingError(
      PaymentSummary.parse(schema),
      expectedKeyPath: \PaymentSummarySchema.sessionStartedAt,
      in: schema,
    )
  }
}
