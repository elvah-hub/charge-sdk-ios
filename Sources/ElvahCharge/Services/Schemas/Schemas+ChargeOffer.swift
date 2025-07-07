// Copyright elvah. All rights reserved.

import Foundation

extension ChargeOffer {
	static func parse(_ response: ChargeOfferSchema) throws(NetworkError) -> ChargeOffer {
		guard let expiresAt = Date.from(iso8601: response.offer.expiresAt) else {
			Elvah.logger.parseError(in: response, for: \.offer.expiresAt)
			throw NetworkError.cannotParseServerResponse
		}

		guard let offerType = ChargeOffer.OfferType(rawValue: response.offer.type) else {
			Elvah.logger.parseError(in: response, for: \.offer.type)
			throw NetworkError.cannotParseServerResponse
		}

		var originalPrice: ChargePrice?
		if let originalPriceSchema = response.offer.originalPrice {
			originalPrice = try ChargePrice.parse(originalPriceSchema)
		}

		return try ChargeOffer(
			chargePoint: ChargePoint.parse(response),
			price: ChargePrice.parse(response.offer.price),
			originalPrice: originalPrice,
			type: offerType,
			campaignEndDate: Date.from(iso8601: response.offer.campaignEndsAt),
			expiresAt: expiresAt
		)
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
		var signedOffer: String? // TODO: Have another schema with signedOffer
	}

	struct PowerSpecificationSchema: Decodable {
		var type: String
		var maxPowerInKW: Double
	}
}
