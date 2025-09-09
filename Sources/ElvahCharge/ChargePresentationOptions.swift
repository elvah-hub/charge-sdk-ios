// Copyright © elvah. All rights reserved.

import Foundation

/// Options to configure visibility of certain UI elements in charge presentation flows.
public struct ChargePresentationOptions: OptionSet, Sendable {
	public let rawValue: Int

	/// Create a new set of presentation options
	/// - Parameter rawValue: The raw bitmask value
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}

	/// Hides operator details in headers where shown.
	public static let hideOperatorDetails = ChargePresentationOptions(rawValue: 1 << 0)

	/// Hides the discount banner in offer detail lists.
	public static let hideDiscountBanner = ChargePresentationOptions(rawValue: 1 << 1)
}
