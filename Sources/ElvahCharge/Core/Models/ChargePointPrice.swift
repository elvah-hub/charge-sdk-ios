// Copyright © elvah. All rights reserved.

import Foundation

package struct ChargePointPrice: Hashable, Codable, Sendable {
	package var evseId: String
	package var value: Currency

	package init(evseId: String, value: Currency) {
		self.evseId = evseId
		self.value = value
	}
}

package extension ChargePointPrice {
	static func mockLoading(evseId: String) -> ChargePointPrice {
		.init(evseId: evseId, value: .init(0.42, identifier: "EUR"))
	}

	static let mockAvailable = ChargePointPrice(
		evseId: ChargePointDetails.mockAvailable.evseId,
		value: .init(0.42, identifier: "EUR")
	)

	static let mockUnavailable = ChargePointPrice(
		evseId: ChargePointDetails.mockUnavailable.evseId,
		value: .init(0.85, identifier: "EUR")
	)

	static let mockOutOfService = ChargePointPrice(
		evseId: ChargePointDetails.mockOutOfService.evseId,
		value: .init(0.23, identifier: "EUR")
	)
}
