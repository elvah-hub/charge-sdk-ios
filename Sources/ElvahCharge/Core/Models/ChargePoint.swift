// Copyright © elvah. All rights reserved.

import SwiftUI

/// A plug that can be connected to an electric car to charge it.
package struct ChargePoint: Identifiable, Hashable, Codable, Sendable {
	/// a unique identification for the charge point.
	package var id: String { details.id }

	package var details: ChargePointDetails
	package var price: ChargePrice

	package init(details: ChargePointDetails, price: ChargePrice) {
		self.details = details
		self.price = price
	}
}

// MARK: - Mock Data

package extension ChargePoint {
	static func mockLoading(evseId: String) -> ChargePoint {
		.init(details: .mockLoading(evseId: evseId), price: .mock)
	}

	static let mockAvailable = ChargePoint(details: .mockAvailable, price: .mock)
	static let mockUnavailable = ChargePoint(details: .mockUnavailable, price: .mock)
	static let mockOutOfService = ChargePoint(details: .mockOutOfService, price: .mock)
}
