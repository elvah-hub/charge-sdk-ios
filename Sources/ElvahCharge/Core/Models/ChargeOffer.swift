// Copyright © elvah. All rights reserved.

import SwiftUI

public struct ChargeOffer: Codable, Hashable, Identifiable, Sendable {
	public var id: String

	public var evseId: String {
		chargePoint.evseId
	}

	public var chargePoint: ChargePoint
	public var price: ChargePrice
	public var originalPrice: ChargePrice?
	public var type: ChargeOffer.OfferType
	public var campaignEndDate: Date
	public var expiresAt: Date

	public init(
		id: String,
		chargePoint: ChargePoint,
		price: ChargePrice,
		originalPrice: ChargePrice?,
		type: ChargeOffer.OfferType,
		campaignEndDate: Date?,
		expiresAt: Date,
	) {
		self.id = id
		self.chargePoint = chargePoint
		self.price = price
		self.originalPrice = originalPrice
		self.type = type
		self.campaignEndDate = campaignEndDate ?? .distantPast // TODO: Find better solution
		self.expiresAt = expiresAt
	}
	
	/// Returns `true` the offer is discounted.
	///
	/// This is equivalent to checking if ``ChargeOffer/originalPrice`` is not `nil`.
	package var isDiscounted: Bool {
		originalPrice != nil
	}

	/// Returns `true` if the associated campaign has ended, `false` otherwise.
	package var hasEnded: Bool {
		campaignEndDate < Date()
	}
}

public extension ChargeOffer {
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
