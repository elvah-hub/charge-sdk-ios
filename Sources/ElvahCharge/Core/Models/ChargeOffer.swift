// Copyright © elvah. All rights reserved.

import SwiftUI

package struct ChargeOffer: Codable, Hashable, Identifiable, Sendable {
	package var id: String

	package var evseId: String {
		chargePoint.evseId
	}

	package var chargePoint: ChargePoint
	package var price: ChargePrice
	package var originalPrice: ChargePrice?
	package var type: ChargeOffer.OfferType
	package var campaignEndDate: Date?
	package var expiresAt: Date
	package var signedOffer: String

	package init(
		id: String,
		chargePoint: ChargePoint,
		price: ChargePrice,
		originalPrice: ChargePrice?,
		type: ChargeOffer.OfferType,
		campaignEndDate: Date?,
		expiresAt: Date,
		signedOffer: String
	) {
		self.id = id
		self.chargePoint = chargePoint
		self.price = price
		self.originalPrice = originalPrice
		self.type = type
		self.campaignEndDate = campaignEndDate
		self.expiresAt = expiresAt
		self.signedOffer = signedOffer
	}
	
	/// Returns `true` the offer is discounted.
	///
	/// This is equivalent to checking if ``ChargeOffer/originalPrice`` is not `nil`.
	package var isDiscounted: Bool {
		originalPrice != nil
	}

	/// Returns `true` if the associated campaign has ended, `false` otherwise.
	package var hasEnded: Bool {
		(campaignEndDate ?? .distantPast) < Date()
	}
}

package extension ChargeOffer {
	enum OfferType: String, Codable, Hashable, Sendable {
		case standard = "STANDARD"
		case campaign = "CAMPAIGN"
	}
}

package extension ChargeOffer {
	static var mockAvailable: ChargeOffer {
		ChargeOffer(
			id: "mock offer available",
			chargePoint: .mockAvailable,
			price: ChargePrice.mock,
			originalPrice: nil,
			type: .campaign,
			campaignEndDate: Date().addingTimeInterval(20),
			expiresAt: Date().addingTimeInterval(120),
			signedOffer: "mock deal"
		)
	}

	static var mockUnavailable: ChargeOffer {
		ChargeOffer(
			id: "mock offer unavailable",
			chargePoint: .mockUnavailable,
			price: ChargePrice.mock,
			originalPrice: nil,
			type: .campaign,
			campaignEndDate: Date().addingTimeInterval(-10),
			expiresAt: Date().addingTimeInterval(120),
			signedOffer: "mock deal"
		)
	}

	static var mockOutOfService: ChargeOffer {
		ChargeOffer(
			id: "mock offer out of service",
			chargePoint: .mockOutOfService,
			price: ChargePrice.mock,
			originalPrice: nil,
			type: .campaign,
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
