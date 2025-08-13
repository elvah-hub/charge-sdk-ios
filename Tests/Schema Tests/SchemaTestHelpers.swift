// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

extension Tag {
  @Tag static var parsing: Self
}

/// Shared helper functions for schema parsing tests
struct SchemaTestHelpers {
  /// Creates a decoder configured for testing JSON schema parsing
  static func createDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }

  /// Helper to decode JSON string into a schema type
  static func decodeSchema<T: Decodable>(_ jsonString: String, as type: T.Type) throws -> T {
    let data = jsonString.data(using: .utf8)!
    return try createDecoder().decode(type, from: data)
  }

  /// Helper to verify that parsing throws a NetworkError.Client.parsing error
  static func expectParsingError<T, Root, Value>(
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