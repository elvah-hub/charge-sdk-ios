// Copyright © elvah. All rights reserved.

import Foundation

/// A type representing a currency.
package struct Currency: Codable, Hashable, Comparable, ExpressibleByFloatLiteral {
	/// The amount.
	package var amount: Double

	/// The identifier.
	package var identifier: String

	/// A type representing a currency.
	///
	/// - Parameters:
	///   - amount: The amount.
	///   - identifier: The identifier. Defaults to "EUR".
	package init(_ amount: Double, identifier: String = "EUR") {
		self.amount = amount
		self.identifier = identifier
	}

	/// Initializes a `Currency` object from a float literal.
	///
	/// - Warning: This is only meant to be used for debugging and testing purpose! The currency's
	/// identifier will always be "EUR".
	/// - Parameter value: The float literal.
	package init(floatLiteral value: FloatLiteralType) {
		self.init(value, identifier: "EUR")
	}

	/// Returns the formatted string representation of the currency.
	///
	/// - Returns: A string representing the formatted currency amount.
	@MainActor package func formatted() -> String {
		if amount.truncatingRemainder(dividingBy: 100) == 0 {
			return amount.formatted(.currency(code: identifier).precision(.fractionLength(0)))
		} else {
			return amount.formatted(.currency(code: identifier).precision(.fractionLength(2)))
		}
	}

	package static func < (lhs: Currency, rhs: Currency) -> Bool {
		lhs.amount < rhs.amount
	}

	package static func * (lhs: Currency, rhs: Double) -> Currency {
		let product = lhs.amount * rhs
		return Currency(product, identifier: lhs.identifier)
	}
}
