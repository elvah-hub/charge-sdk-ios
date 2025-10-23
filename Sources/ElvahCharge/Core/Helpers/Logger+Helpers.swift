// Copyright © elvah. All rights reserved.

import Foundation
import OSLog

package extension Logger {
  func parseError(for name: String, value: String?) {
    error("Unable to parse \(name): \(value ?? "[nil]")")
  }

  func parseError<K>(in object: K, for keyPath: KeyPath<K, some Any>) {
    error(
      "Unable to parse \(String(reflecting: keyPath)): \(String(reflecting: object[keyPath: keyPath]))",
    )
  }

  /// Logs a parsing error from a NetworkError.Client.ParsingError
  func parseError(_ error: NetworkError.Client.ParsingError) {
    self.error("\(error.debugDescription)")
  }
}

// MARK: - NetworkError.Client.ParsingError Creation Helpers

package extension NetworkError.Client.ParsingError {
  /// Creates a parsing error for a specific field name and value
  static func field(
    _ name: String,
    value: String? = nil,
    expectedType: String? = nil,
    context: String? = nil,
  ) -> NetworkError.Client.ParsingError {
    NetworkError.Client.ParsingError(
      fieldName: name,
      value: value,
      expectedType: expectedType,
      context: context,
    )
  }

  /// Creates a parsing error from a KeyPath
  static func keyPath<Root>(
    in object: Root,
    keyPath: KeyPath<Root, some Any>,
    expectedType: String? = nil,
    context: String? = nil,
  ) -> NetworkError.Client.ParsingError {
    NetworkError.Client.ParsingError(
      fieldName: String(reflecting: keyPath),
      value: String(reflecting: object[keyPath: keyPath]),
      expectedType: expectedType,
      context: context,
    )
  }
}
