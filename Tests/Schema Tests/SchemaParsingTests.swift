// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

/// Tests for schema parsing functionality across all schema types.
///
/// These tests ensure that:
/// - Valid schemas parse correctly into domain models
/// - Invalid/malformed schemas throw appropriate NetworkError.Client errors
/// - Edge cases like missing optional fields are handled properly
/// - Error reporting provides clear debugging information
@Suite("Schema Parsing Tests")
struct SchemaParsingTests {
	/// Creates a decoder configured for testing JSON schema parsing
	var decoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder
	}()

	/// Helper to decode JSON string into a schema type
	func decodeSchema<T: Decodable>(_ jsonString: String, as type: T.Type) throws -> T {
		let data = jsonString.data(using: .utf8)!
		return try decoder.decode(type, from: data)
	}

	/// Helper to verify that parsing throws a NetworkError.Client.parsing error
	func expectParsingError<T, Root, Value>(
		_ expression: @autoclosure () throws -> T,
		expectedKeyPath: KeyPath<Root, Value>,
		in object: Root
	) throws {
		var caught: NetworkError.Client.ParsingError?

		do {
			_ = try expression()
		} catch let error as NetworkError.Client {
			if case let .parsing(parsingError) = error {
				caught = parsingError
			}
		}

		guard let parsingError = caught else {
			Issue.record("Expected NetworkError.Client.parsing to be thrown")
			return
		}

		let expectedField = String(reflecting: expectedKeyPath)
		#expect(parsingError.fieldName == expectedField)
	}
}
