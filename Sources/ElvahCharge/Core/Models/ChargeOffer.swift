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
	public var type: ChargeOffer.OfferType

	/// The site that this charge offer is part of.
	package var site: Site

	package init(
		chargePoint: ChargePoint,
		price: ChargePrice,
		originalPrice: ChargePrice?,
		type: OfferType,
		site: Site,
	) {
		self.chargePoint = chargePoint
		self.price = price
		self.originalPrice = originalPrice
		self.type = type
		self.site = site
	}

	/// Information about a campaign that is associated with this offer, if there is one.
	///
	/// - Note: This property will only hold a value when the charge offer is part of a campaign.
	public var campaign: CampaignInfo? {
		guard case let .campaign(campaignInfo) = type else {
			return nil
		}

		return campaignInfo
	}

	/// A flag indicating if the offer is still available.
	///
	/// This flag will always be `true` for offers that are not part of a campaign.
	public var isAvailable: Bool {
		if let campaign {
			return campaign.hasEnded == false
		}

		return true
	}

	/// Returns `true` if the offer is part of a campaign.
	public var hasCampaign: Bool {
		campaign != nil
	}

	/// Returns `true` the offer is discounted.
	package var isDiscounted: Bool {
		originalPrice != nil && isAvailable
	}
}

public extension ChargeOffer {
	enum OfferType: Codable, Hashable, Sendable {
		case standard
		case campaign(CampaignInfo)

		/// Returns `true` if the offer is a standard offer.
		public var isStandard: Bool {
			if case .standard = self {
				return true
			}
			return false
		}

		/// Returns `true` if the offer is a campaign offer.
		public var isCampaign: Bool {
			if case .campaign = self {
				return true
			}
			return false
		}
	}

	struct CampaignInfo: Codable, Hashable, Sendable {
		/// The date at which the associated campaign will end for this charge offer.
		public let endDate: Date

		/// Returns `true` if the campaign has ended, `false` otherwise.
		public var hasEnded: Bool {
			endDate < Date()
		}
	}
}

package extension ChargeOffer {
	static var simulation: ChargeOffer {
		ChargeOffer(
			chargePoint: .mockAvailable,
			price: ChargePrice.mock,
			originalPrice: nil,
			type: .standard,
			site: .mock,
		)
	}

	/// Creates a simulated charge offer with the specific evseId and randomized properties.
	/// - Parameter evseId: The evse ids for the charge point
	/// - Returns: A ChargeOffer with randomized pricing and potentially campaign status
	static func simulation(evseId: String) -> ChargeOffer {
		let chargePoint = ChargePoint.simulation(evseId: evseId)
		let basePrice = ChargePrice.randomizedPrice()

		// Randomly determine if this should be a campaign offer (30% chance)
		let isCampaign = Double.random(in: 0 ... 1) < 0.3

		let (finalPrice, originalPrice, offerType): (ChargePrice, ChargePrice?, OfferType)

		if isCampaign {
			let campaignPrice = ChargePrice.campaignPrice(from: basePrice)
			let campaignEndDate = Date().addingTimeInterval(Double.random(in: 3600 ... 604_800))
			finalPrice = campaignPrice
			originalPrice = basePrice
			offerType = .campaign(CampaignInfo(endDate: campaignEndDate))
		} else {
			finalPrice = basePrice
			originalPrice = nil
			offerType = .standard
		}

		return ChargeOffer(
			chargePoint: chargePoint,
			price: finalPrice,
			originalPrice: originalPrice,
			type: offerType,
			site: .simulation,
		)
	}

	static var mockAvailable: ChargeOffer {
		ChargeOffer(
			chargePoint: .mockAvailable,
			price: ChargePrice.mock,
			originalPrice: ChargePrice.mock2,
			type: .campaign(CampaignInfo(endDate: Date().addingTimeInterval(20))),
			site: .mock,
		)
	}

	static var mockUnavailable: ChargeOffer {
		ChargeOffer(
			chargePoint: .mockUnavailable,
			price: ChargePrice.mock2,
			originalPrice: ChargePrice.mock3,
			type: .campaign(CampaignInfo(endDate: Date().addingTimeInterval(-10))),
			site: .mock,
		)
	}

	static var mockOutOfService: ChargeOffer {
		ChargeOffer(
			chargePoint: .mockOutOfService,
			price: ChargePrice.mock3,
			originalPrice: nil,
			type: .standard, // .campaign(CampaignInfo(endDate: Date().addingTimeInterval(30))),
			site: .mock,
		)
	}
}

package extension [ChargeOffer] {
	var hasDiscounts: Bool {
		contains(where: \.isDiscounted)
	}

	var cheapestOffer: ChargeOffer? {
		sorted(using: KeyPathComparator(\.price.pricePerKWh)).first
	}

	var earliestEndingOffer: ChargeOffer? {
		sorted(using: KeyPathComparator(\.price.pricePerKWh)).first
	}

	/// The largest common prefix across all offer EVSE identifiers.
	var largestCommonEvseIdPrefix: String {
		map(\.chargePoint).largestCommonEvseIdPrefix
	}
}
