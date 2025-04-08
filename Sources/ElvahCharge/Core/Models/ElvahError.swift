// Copyright © elvah. All rights reserved.

import Foundation

public extension Elvah {
	/// An error from the SDK.
	enum Error: Swift.Error, Sendable {
		/// A ``NetworkError``.
		case network(NetworkError)

		/// An error indicating missing or invalid authorization.
		///
		/// This error typically occurs when the api key you initialized the Elvah SDK is either missing
		/// or invalid.
		case unauthorized

		/// An error indicating that a request was cancelled.
		case cancelled

		/// An unknown error.
		case unknown(any Swift.Error)
	}
}

extension Elvah.Error: CustomStringConvertible, LocalizedError {
	public var description: String {
		switch self {
		case let .network(networkError):
			return networkError.description
		case .unauthorized:
			return "Unauthorized. Please check your API key."
		case .cancelled:
			return "The request was cancelled."
		case let .unknown(error):
			return "An unknown error has occurred: \(error.localizedDescription)"
		}
	}

	/// A localized message describing what error occurred.
	public var errorDescription: String? {
		return description
	}
}
