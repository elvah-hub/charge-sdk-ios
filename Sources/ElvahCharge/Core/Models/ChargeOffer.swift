// Copyright © elvah. All rights reserved.

import SwiftUI

/// A charge point with attached pricing information.
///
/// - Important: The prices included are considered “preview prices” until the offer is signed.
public struct ChargeOffer: Codable, Hashable, Identifiable, Sendable {
	/// The unique identifier for this charge offer.
	public var id: String {
		evseId
	}

	/// The evse id of the charge point associated with this charge offer.
	public var evseId: String {
		chargePoint.evseId
	}

	/// The charge point associated with this charge offer.
	public var chargePoint: ChargePoint

	/// The price information for this charge offer.
	public var price: ChargePrice

	/// The original price before any discounts were applied, if there are any.
	public var originalPrice: ChargePrice?

	/// The type of offer, e.g. `standard` or `campaign`.
	///
	/// A `campaign` type will usually have a discounted price.
	package var type: ChargeOffer.OfferType

	/// The information about the associated campaign, if there is one.
	///
	/// - Note: You should not use this property directly. Instead use accessors in the ``Campaign``
	/// object, like ``Campaign/endDate(for:)``.
	/// - Note: This property will only hold a value when the charge offer is part of a ``Campaign``.
	package var campaignInfo: CampaignInfo?

	/// The date at which the offer expires, i.e. when the price might change.
	public var expiresAt: Date

	public init(
		chargePoint: ChargePoint,
		price: ChargePrice,
		originalPrice: ChargePrice?,
		type: OfferType,
		campaignInfo: CampaignInfo?,
		expiresAt: Date,
	) {
		self.chargePoint = chargePoint
		self.price = price
		self.originalPrice = originalPrice
		self.type = type
		self.campaignInfo = campaignInfo
		self.expiresAt = expiresAt
	}

	/// Returns `true` the offer is discounted.
	///
	/// This is equivalent to checking if ``ChargeOffer/originalPrice`` is not `nil`.
	package var isDiscounted: Bool {
		originalPrice != nil
	}

	/// Returns `true` if the associated campaign has ended, `false` otherwise.
	///
	/// - Note: This property will always return `true` for charge offers that are not part of a
	/// campaign.
	package var hasEnded: Bool {
		guard let campaignInfo else {
			return true
		}

		return campaignInfo.endDate < Date()
	}
}

public extension ChargeOffer {
	enum OfferType: String, Codable, Hashable, Sendable {
		case standard = "STANDARD"
		case campaign = "CAMPAIGN"
	}

	struct CampaignInfo: Codable, Hashable, Sendable {
		/// The date at which the associated campaign will end for this charge offer.
		let endDate: Date
	}
}

package extension ChargeOffer {
	static var mockAvailable: ChargeOffer {
		ChargeOffer(
			chargePoint: .mockAvailable,
			price: ChargePrice.mock,
			originalPrice: nil,
			type: .campaign,
			campaignInfo: CampaignInfo(endDate: Date().addingTimeInterval(20)),
			expiresAt: Date().addingTimeInterval(120),
		)
	}

	static var mockUnavailable: ChargeOffer {
		ChargeOffer(
			chargePoint: .mockUnavailable,
			price: ChargePrice.mock,
			originalPrice: nil,
			type: .campaign,
			campaignInfo: CampaignInfo(endDate: Date().addingTimeInterval(-10)),
			expiresAt: Date().addingTimeInterval(120),
		)
	}

	static var mockOutOfService: ChargeOffer {
		ChargeOffer(
			chargePoint: .mockOutOfService,
			price: ChargePrice.mock2,
			originalPrice: nil,
			type: .campaign,
			campaignInfo: CampaignInfo(endDate: Date().addingTimeInterval(30)),
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
