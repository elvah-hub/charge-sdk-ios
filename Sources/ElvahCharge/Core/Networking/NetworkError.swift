// Copyright © elvah. All rights reserved.

import Foundation

package typealias NetworkError = Elvah.NetworkError

public extension Elvah {
  /// An error type describing common network-related failures that can occur within the SDK.
  ///
  /// `NetworkError` covers both client-side and server-side error conditions,
  /// including connection failures, response parsing issues, HTTP error responses,
  /// and unexpected or unknown failures.
  enum NetworkError: Swift.Error, Sendable, Hashable {
    // MARK: - Client-side Errors

    /// Indicates a low-level networking failure, such as no internet connection or a DNS resolution
    /// error.
    case connection

    /// Indicates a failure to encode or serialize the request before sending it to the server.
    case cannotParseClientRequest

    /// Indicates that the SDK could not parse a valid response from the server.
    case cannotParseServerResponse

    /// Indicates that the server returned a response, but it was unexpected or did not match the
    /// expected format or structure.
    case unexpectedServerResponse

    // MARK: - Server-side HTTP Errors

    /// Unauthorized access error, typically corresponding to HTTP 401 (unauthenticated) or 403
    /// (forbidden).
    case unauthorized

    /// Indicates that the requested resource was not found (typically HTTP 404).
    case notFound

    /// Represents server-side errors (typically HTTP 5xx, such as 500 Internal Server Error).
    case server

    // MARK: - Other

    /// An unknown or unclassified error occurred.
    case unknown

    /// The code to identify the specific error.
    public var code: String {
      switch self {
      case .connection:
        "N-01"
      case .cannotParseClientRequest:
        "N-02"
      case .cannotParseServerResponse:
        "N-03"
      case .unexpectedServerResponse:
        "N-04"
      case .unauthorized:
        "N-05"
      case .notFound:
        "N-06"
      case .server:
        "N-07"
      case .unknown:
        "N-99"
      }
    }
  }
}

// MARK: - CustomStringConvertible & LocalizedError

extension Elvah.NetworkError: CustomStringConvertible, LocalizedError {
  /// A human-readable description of the error.
  public var description: String {
    switch self {
    case .connection:
      "Connection error: a network connection could not be established."
    case .cannotParseClientRequest:
      "Request encoding error: failed to serialize the request before sending."
    case .cannotParseServerResponse:
      "Parsing error: failed to parse the server response."
    case .unexpectedServerResponse:
      "Unexpected server response: the format or content was not recognized."
    case .unauthorized:
      "Unauthorized access: authentication is required (HTTP 401/403)."
    case .notFound:
      "Resource not found (HTTP 404)."
    case .server:
      "Server error: a problem occurred on the server (HTTP 5xx)."
    case .unknown:
      "An unknown error occurred."
    }
  }

  /// A localized message describing what error occurred.
  public var errorDescription: String? {
    description
  }

  /// Returns a representative HTTP status code, if applicable.
  ///
  /// This helps consumers map error types to status codes commonly used in HTTP-based APIs.
  /// For example:
  /// - `.unauthorized` → 401
  /// - `.notFound` → 404
  /// - `.server` → 500
  /// For non-HTTP related cases, this property returns `nil`.
  public var httpStatusCode: Int? {
    switch self {
    case .unauthorized:
      401
    case .notFound:
      404
    case .server:
      500
    default:
      nil
    }
  }
}
