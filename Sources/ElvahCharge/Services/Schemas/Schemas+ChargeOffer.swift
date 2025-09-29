// Copyright © elvah. All rights reserved.

import Foundation

extension ChargeOffer {
	static func parse(
		_ response: ChargeOfferSchema,
		in site: Site
	) throws(NetworkError.Client) -> ChargeOffer {
		var originalPrice: ChargePrice?
		if let originalPriceSchema = response.offer.originalPrice {
			originalPrice = try ChargePrice.parse(originalPriceSchema)
		}

		var offerType: ChargeOffer.OfferType
		switch response.offer.type {
		case "STANDARD":
			offerType = .standard
		case "CAMPAIGN":
			guard let endDate = Date.from(iso8601: response.offer.campaignEndsAt) else {
				throw .parsing(.keyPath(in: response, keyPath: \.offer.campaignEndsAt))
			}
			offerType = .campaign(CampaignInfo(endDate: endDate))
		default:
			throw .parsing(.keyPath(in: response, keyPath: \.offer.type))
		}

		return try ChargeOffer(
			chargePoint: ChargePoint.parse(response),
			price: ChargePrice.parse(response.offer.price),
			originalPrice: originalPrice,
			type: offerType,
			site: site
		)
	}
}

struct ChargeOfferSchema: Decodable {
	var availability: String
	var evseId: String
	var powerSpecification: PowerSpecificationSchema?
	var offer: OfferSchema

	struct OfferSchema: Decodable {
		var type: String
		var campaignEndsAt: String?
		var price: ChargePriceSchema
		var originalPrice: ChargePriceSchema?
		var expiresAt: String
		var signedOffer: String?
	}

	struct PowerSpecificationSchema: Decodable {
		var type: String
		var maxPowerInKW: Double
	}
}
