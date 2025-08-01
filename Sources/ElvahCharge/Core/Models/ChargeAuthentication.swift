// Copyright © elvah. All rights reserved.

import Foundation

/// An object holding information about charge authentication.
package struct ChargeAuthentication: Codable, Hashable, Sendable {
	/// The authentication token used to charge.
	package var token: String

	/// The date at which the authentication token expires, or `nil` if
	/// it doesn't expire.
	package var expiryDate: Date?

	/// Main initializer.
	/// - Parameters:
	///   - token: The authentication token.
	///   - expiryDate: The expiry date of the authentication token, if available.
	package init(token: String, expiryDate: Date?) {
		self.token = token
		self.expiryDate = expiryDate
	}
}

package extension ChargeAuthentication {
	static var simulation: ChargeAuthentication {
		.init(token: "simulated authentication", expiryDate: .distantFuture)
	}

	static var mock: ChargeAuthentication {
		.init(token: "mock authentication", expiryDate: .distantFuture)
	}
}
