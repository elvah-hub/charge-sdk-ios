// Copyright © elvah. All rights reserved.

import Foundation

extension ChargeOffer {
	static func parse(_ response: ChargeOfferSchema) throws(NetworkError) -> ChargeOffer {
		guard let expiresAt = Date.from(iso8601: response.offer.expiresAt) else {
			Elvah.logger.parseError(in: response, for: \.offer.expiresAt)
			throw NetworkError.cannotParseServerResponse
		}

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
				Elvah.logger.parseError(in: response, for: \.offer.campaignEndsAt)
				throw NetworkError.cannotParseServerResponse
			}
			offerType = .campaign(CampaignInfo(endDate: endDate))
		default:
			Elvah.logger.parseError(in: response, for: \.offer.type)
			throw NetworkError.cannotParseServerResponse
		}

		return try ChargeOffer(
			chargePoint: ChargePoint.parse(response),
			price: ChargePrice.parse(response.offer.price),
			originalPrice: originalPrice,
			type: offerType,
			validUntil: expiresAt
		)
	}

	static func parseSigned(_ response: ChargeOfferSchema) throws(NetworkError) -> SignedChargeOffer {
		let chargeOffer = try ChargeOffer.parse(response)

		guard let signedOffer = response.offer.signedOffer else {
			Elvah.logger.parseError(in: response, for: \.offer.signedOffer)
			throw NetworkError.cannotParseServerResponse
		}

		return SignedChargeOffer(offer: chargeOffer, signedOffer: signedOffer)
	}
}

struct ChargeOfferSchema: Decodable {
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
