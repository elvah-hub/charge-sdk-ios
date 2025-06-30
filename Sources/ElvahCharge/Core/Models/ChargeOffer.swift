// Copyright © elvah. All rights reserved.

import SwiftUI

package struct ChargeOffer: Codable, Hashable, Identifiable, Sendable {
	package var id: String

	package var evseId: String {
		chargePoint.evseId
	}

	package var chargePoint: ChargePointDetails
	package var price: ChargePrice
	package var campaignEndDate: Date
	package var expiresAt: Date
	package var signedOffer: String

	package init(
		id: String,
		chargePoint: ChargePointDetails,
		price: ChargePrice,
		campaignEndDate: Date,
		expiresAt: Date,
		signedOffer: String
	) {
		self.id = id
		self.chargePoint = chargePoint
		self.price = price
		self.campaignEndDate = campaignEndDate
		self.expiresAt = expiresAt
		self.signedOffer = signedOffer
	}

	/// Returns `true` if the associated campaign has ended, `false` otherwise.
	package var hasEnded: Bool {
		campaignEndDate < Date()
	}
}

package extension ChargeOffer {
	static var mockAvailable: ChargeOffer {
		ChargeOffer(
			id: "mock deal available",
			chargePoint: .mockAvailable,
			price: ChargePrice.mock,
			campaignEndDate: Date().addingTimeInterval(20),
			expiresAt: Date().addingTimeInterval(120),
			signedOffer: "mock deal"
		)
	}

	static var mockUnavailable: ChargeOffer {
		ChargeOffer(
			id: "mock deal unavailable",
			chargePoint: .mockUnavailable,
			price: ChargePrice.mock,
			campaignEndDate: Date().addingTimeInterval(-10),
			expiresAt: Date().addingTimeInterval(120),
			signedOffer: "mock deal"
		)
	}

	static var mockOutOfService: ChargeOffer {
		ChargeOffer(
			id: "mock deal out of service",
			chargePoint: .mockOutOfService,
			price: ChargePrice.mock,
			campaignEndDate: Date().addingTimeInterval(30),
			expiresAt: Date().addingTimeInterval(120),
			signedOffer: "mock deal"
		)
	}
}

package extension [ChargeOffer] {
	var cheapestOffer: ChargeOffer? {
		sorted(using: KeyPathComparator(\.price.pricePerKWh)).first
	}

	var earliestEndingOffer: ChargeOffer? {
		sorted(using: KeyPathComparator(\.price.pricePerKWh)).first
	}
}
