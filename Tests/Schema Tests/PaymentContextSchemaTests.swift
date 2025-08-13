// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

/// Tests for PaymentContext schema parsing functionality.
@Suite("PaymentContext Schema Parsing Tests", .tags(.parsing))
struct PaymentContextSchemaTests {
	@Test("PaymentContext schema parses valid complete data correctly")
	func paymentContextValidCompleteParsing() throws {
		// Given: Valid complete payment context schema JSON
		let validJSON = """
		{
		  "paymentId": "payment_1234567890",
		  "clientSecret": "pi_1234567890_secret_abc123",
		  "paymentIntentId": "pi_1234567890",
		  "accountId": "acct_1234567890",
		  "authorisationAmount": {
		    "value": 25.50,
		    "currency": "EUR"
		  },
		  "organisationDetails": {
		    "companyName": "Test Charging Company",
		    "logoUrl": "https://example.com/logo.png",
		    "privacyUrl": "https://example.com/privacy",
		    "termsOfConditionUrl": "https://example.com/terms",
		    "supportContacts": [
		      {
		        "supportType": "EMAIL",
		        "value": "support@example.com"
		      },
		      {
		        "supportType": "PHONE_NUMBER",
		        "value": "+49123456789"
		      },
		      {
		        "supportType": "WHATSAPP",
		        "value": "+49987654321"
		      },
		      {
		        "supportType": "URL",
		        "value": "https://example.com/support"
		      }
		    ]
		  }
		}
		"""

		// When: Parsing the schema
		let schema = try SchemaTestHelpers.decodeSchema(validJSON, as: PaymentContextSchema.self)
		let paymentContext = try PaymentContext.parse(schema)

		// Then: All values are correctly parsed
		#expect(paymentContext.paymentId == "payment_1234567890")
		#expect(paymentContext.clientSecret == "pi_1234567890_secret_abc123")
		#expect(paymentContext.paymentIntentId == "pi_1234567890")
		#expect(paymentContext.accountId == "acct_1234567890")
		#expect(paymentContext.authorizationAmount.amount == 25.50)
		#expect(paymentContext.authorizationAmount.identifier == "EUR")

		// Organisation details
		#expect(paymentContext.organisationDetails.companyName == "Test Charging Company")
		#expect(paymentContext.organisationDetails.logoUrl?
			.absoluteString == "https://example.com/logo.png"
		)
		#expect(paymentContext.organisationDetails.privacyUrl?
			.absoluteString == "https://example.com/privacy"
		)
		#expect(paymentContext.organisationDetails.termsOfConditionUrl?
			.absoluteString == "https://example.com/terms"
		)
		#expect(paymentContext.organisationDetails.hasLegalUrls == true)

		// Support methods
		#expect(paymentContext.organisationDetails.supportMethods.count == 4)
		#expect(paymentContext.organisationDetails.supportMethods
			.contains(.email("support@example.com"))
		)
		#expect(paymentContext.organisationDetails.supportMethods.contains(.phone("+49123456789")))
		#expect(paymentContext.organisationDetails.supportMethods.contains(.whatsApp("+49987654321")))
		#expect(paymentContext.organisationDetails.supportMethods
			.contains(.website(URL(string: "https://example.com/support")!))
		)
	}

	@Test("PaymentContext schema parses minimal required fields correctly")
	func paymentContextMinimalFields() throws {
		// Given: Schema with minimal required fields
		let minimalJSON = """
		{
		  "paymentId": "payment_minimal",
		  "clientSecret": "pi_minimal_secret",
		  "paymentIntentId": "pi_minimal",
		  "accountId": "acct_minimal",
		  "authorisationAmount": {
		    "value": 10.00,
		    "currency": "USD"
		  },
		  "organisationDetails": {
		    "companyName": null,
		    "logoUrl": null,
		    "privacyUrl": null,
		    "termsOfConditionUrl": null,
		    "supportContacts": []
		  }
		}
		"""

		// When: Parsing the schema
		let schema = try SchemaTestHelpers.decodeSchema(minimalJSON, as: PaymentContextSchema.self)
		let paymentContext = try PaymentContext.parse(schema)

		// Then: Required fields are parsed, optional fields are nil or empty
		#expect(paymentContext.paymentId == "payment_minimal")
		#expect(paymentContext.clientSecret == "pi_minimal_secret")
		#expect(paymentContext.paymentIntentId == "pi_minimal")
		#expect(paymentContext.accountId == "acct_minimal")
		#expect(paymentContext.authorizationAmount.amount == 10.00)
		#expect(paymentContext.authorizationAmount.identifier == "USD")

		// Organisation details with null/empty values
		#expect(paymentContext.organisationDetails.companyName == nil)
		#expect(paymentContext.organisationDetails.logoUrl == nil)
		#expect(paymentContext.organisationDetails.privacyUrl == nil)
		#expect(paymentContext.organisationDetails.termsOfConditionUrl == nil)
		#expect(paymentContext.organisationDetails.supportMethods.isEmpty)
		#expect(paymentContext.organisationDetails.hasLegalUrls == false)
	}

	@Test("PaymentContext schema filters invalid support method types")
	func paymentContextInvalidSupportMethodTypes() throws {
		// Given: Schema with mix of valid and invalid support method types
		let mixedSupportMethodsJSON = """
		{
		  "paymentId": "payment_mixed_support",
		  "clientSecret": "pi_mixed_support_secret",
		  "paymentIntentId": "pi_mixed_support",
		  "accountId": "acct_mixed_support",
		  "authorisationAmount": {
		    "value": 12.99,
		    "currency": "SEK"
		  },
		  "organisationDetails": {
		    "companyName": "Mixed Support Company",
		    "logoUrl": null,
		    "privacyUrl": null,
		    "termsOfConditionUrl": null,
		    "supportContacts": [
		      {
		        "supportType": "EMAIL",
		        "value": "valid@example.com"
		      },
		      {
		        "supportType": "INVALID_TYPE",
		        "value": "should-be-filtered"
		      },
		      {
		        "supportType": "PHONE_NUMBER",
		        "value": "+1234567890"
		      },
		      {
		        "supportType": "UNKNOWN",
		        "value": "also-filtered"
		      },
		      {
		        "supportType": "WHATSAPP",
		        "value": "+0987654321"
		      }
		    ]
		  }
		}
		"""

		// When: Parsing the schema
		let schema = try SchemaTestHelpers.decodeSchema(
			mixedSupportMethodsJSON,
			as: PaymentContextSchema.self
		)
		let paymentContext = try PaymentContext.parse(schema)

		// Then: Only valid support methods are included, invalid ones are filtered out
		#expect(paymentContext.organisationDetails.supportMethods.count == 3)
		#expect(paymentContext.organisationDetails.supportMethods.contains(.email("valid@example.com")))
		#expect(paymentContext.organisationDetails.supportMethods.contains(.phone("+1234567890")))
		#expect(paymentContext.organisationDetails.supportMethods.contains(.whatsApp("+0987654321")))
	}
}
