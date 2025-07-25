// Copyright © elvah. All rights reserved.

import Foundation

package extension NetworkError {
	/// A network client error.
	enum Client: Error, Sendable {
		case connection(ConnectionError)
		case encoding(EncodingError)
		case decoding(DecodingError)
		case parsing(ParsingError)
		case serverErrorResponse(ServerErrorResponse)
		case unacceptableStatusCode(httpStatusCode: Int)
		case unknown(underlying: Error)

		/// Returns the HTTP status code if the error encapsulates one.
		package var httpStatusCode: Int? {
			switch self {
			case let .serverErrorResponse(response):
				return response.httpStatusCode
			case let .unacceptableStatusCode(httpStatusCode):
				return httpStatusCode
			default:
				return nil
			}
		}

		/// Indicates whether the error is due to an authentication issue (e.g. HTTP 401 or 403).
		package var isAuthenticationError: Bool {
			guard let status = httpStatusCode else {
				return false
			}
			return status == 401 || status == 403
		}

		// MARK: - External Error

		/// Returns the more opaque, easier to handle `NetworkError` for the UI components.
		package var externalError: NetworkError {
			switch self {
			case .connection:
				return NetworkError.connection
			case .encoding:
				return NetworkError.cannotParseClientRequest
			case .decoding:
				return NetworkError.cannotParseServerResponse
			case .parsing:
				return NetworkError.cannotParseServerResponse
			case let .serverErrorResponse(serverErrorResponse):
				switch serverErrorResponse.httpStatusCode {
				case 401,
				     403:
					return NetworkError.unauthorized
				default:
					return NetworkError.unexpectedServerResponse
				}
			case let .unacceptableStatusCode(httpStatusCode):
				switch httpStatusCode {
				case 401,
				     403:
					return NetworkError.unauthorized
				default:
					return NetworkError.unexpectedServerResponse
				}
			case .unknown:
				return NetworkError.unknown
			}
		}

		// MARK: - Connection Error

		package enum ConnectionError: Sendable, CustomDebugStringConvertible {
			case cannotConnectToHost
			case cannotFindHost
			case networkConnectionLost
			case notConnectedToInternet
			case timedOut
			case unknown(code: Int)

			package static func from(code: Int) -> ConnectionError {
				switch code {
				case NSURLErrorCannotConnectToHost:
					return .cannotConnectToHost
				case NSURLErrorCannotFindHost:
					return .cannotFindHost
				case NSURLErrorNetworkConnectionLost:
					return .networkConnectionLost
				case NSURLErrorNotConnectedToInternet:
					return .notConnectedToInternet
				case NSURLErrorTimedOut:
					return .timedOut
				default:
					return .unknown(code: code)
				}
			}

			package var debugDescription: String {
				switch self {
				case .cannotConnectToHost:
					return "Cannot connect to host."
				case .cannotFindHost:
					return "Cannot find host."
				case .networkConnectionLost:
					return "Network connection was lost."
				case .notConnectedToInternet:
					return "Not connected to the Internet."
				case .timedOut:
					return "The connection timed out."
				case let .unknown(code):
					return "Unknown connection error with code: \(code)."
				}
			}
		}

		// MARK: - Parsing Error

		package struct ParsingError: Error, Sendable, CustomDebugStringConvertible {
			package let fieldName: String
			package let value: String?
			package let expectedType: String?
			package let context: String?

			package init(
				fieldName: String,
				value: String? = nil,
				expectedType: String? = nil,
				context: String? = nil
			) {
				self.fieldName = fieldName
				self.value = value
				self.expectedType = expectedType
				self.context = context
			}

			package var debugDescription: String {
				var description = "Unable to parse '\(fieldName)'"

				if let value = value {
					description += " with value: \(value)"
				}

				if let expectedType = expectedType {
					description += " (expected type: \(expectedType))"
				}

				if let context = context {
					description += " - \(context)"
				}

				return description
			}
		}
	}
}

// MARK: - CustomStringConvertible & LocalizedError Conformance

extension NetworkError.Client: CustomStringConvertible, LocalizedError {
	package var description: String {
		switch self {
		case let .connection(error):
			return "Connection error: \(error.debugDescription)"
		case let .encoding(error):
			return "Encoding error: " + errorDescription(for: error)
		case let .decoding(error):
			return "Decoding error: " + errorDescription(for: error)
		case let .parsing(error):
			return "Parsing error: \(error.debugDescription)"
		case let .serverErrorResponse(error):
			return error.debugDescription
		case let .unacceptableStatusCode(httpStatusCode):
			return "Response with unacceptable status code \(httpStatusCode)"
		case let .unknown(underlying):
			return "An unknown error occurred: \(underlying.localizedDescription)"
		}
	}

	package var errorDescription: String? {
		return description
	}

	/// Provides detailed descriptions for EncodingError cases.
	private func errorDescription(for error: EncodingError) -> String {
		switch error {
		case let .invalidValue(value, context):
			let codingPath = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
			return "Invalid value \(value) encountered. \(context.debugDescription) (Coding path: \(codingPath))."
		@unknown default:
			return "Unknown encoding error."
		}
	}

	/// Provides detailed descriptions for DecodingError cases.
	private func errorDescription(for error: DecodingError) -> String {
		switch error {
		case let .dataCorrupted(context):
			let codingPath = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
			return "Data appears corrupted. \(context.debugDescription) (Coding path: \(codingPath))."
		case let .keyNotFound(key, context):
			let codingPath = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
			return "The key '\(key.stringValue)' was not found. \(context.debugDescription) (Coding path: \(codingPath))."
		case let .typeMismatch(type, context):
			let codingPath = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
			return "Type mismatch for type \(type). \(context.debugDescription) (Coding path: \(codingPath))."
		case let .valueNotFound(type, context):
			let codingPath = context.codingPath.map { $0.stringValue }.joined(separator: " -> ")
			return "Expected value of type \(type) not found. \(context.debugDescription) (Coding path: \(codingPath))."
		@unknown default:
			return "Unknown decoding error."
		}
	}
}
