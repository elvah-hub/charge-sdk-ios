// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

/// Tests for ChargeAuthentication schema parsing functionality.
@Suite("ChargeAuthentication Schema Parsing Tests", .tags(.parsing))
struct ChargeAuthenticationSchemaTests {
  @Test("ChargeAuthentication schema parses valid JSON correctly")
  func chargeAuthenticationValidParsing() throws {
    // Given: Valid charge authentication schema JSON
    let validJSON = """
    {
      "data": {
        "chargeIdentityToken": "auth_token_12345"
      }
    }
    """

    // When: Parsing the schema
    let schema = try SchemaTestHelpers.decodeSchema(validJSON, as: ChargeAuthenticationSchema.self)
    let chargeAuth = try ChargeAuthentication.parse(schema)

    // Then: Values are correctly parsed
    #expect(chargeAuth.token == "auth_token_12345")
    #expect(chargeAuth.expiryDate == nil)
  }
}
