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
		let number = NSNumber(floatLiteral: amount)
		return Self.formatter.string(from: number) ?? ""
	}

	package static func < (lhs: Currency, rhs: Currency) -> Bool {
		lhs.amount < rhs.amount
	}

	package static func * (lhs: Currency, rhs: Double) -> Currency {
		let product = lhs.amount * rhs
		return Currency(product, identifier: lhs.identifier)
	}
}

private extension Currency {
	/// A number formatter configured for currency formatting.
	@MainActor static let formatter: NumberFormatter = {
		let numberFormatter = NumberFormatter()
		numberFormatter.locale = .current
		numberFormatter.numberStyle = .currency
		numberFormatter.minimumFractionDigits = 2
		numberFormatter.maximumFractionDigits = 2
		numberFormatter.currencyCode = "EUR" // SDK only supports Euro for now
		return numberFormatter
	}()
}
