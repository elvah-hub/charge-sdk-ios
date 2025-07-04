// Copyright elvah. All rights reserved.

import Foundation

extension ChargeOffer {
	static func parse(_ response: ChargeOfferSchema) throws(NetworkError) -> ChargeOffer {
		guard let expiresAt = Date.from(iso8601: response.expiresAt) else {
			Elvah.logger.parseError(in: response, for: \.expiresAt)
			throw NetworkError.cannotParseServerResponse
		}

		guard let offerType = ChargeOffer.OfferType(rawValue: response.type) else {
			Elvah.logger.parseError(in: response, for: \.type)
			throw NetworkError.cannotParseServerResponse
		}

		var originalPrice: ChargePrice?
		if let originalPriceSchema = response.originalPrice {
			originalPrice = try ChargePrice.parse(originalPriceSchema)
		}

		return try ChargeOffer(
			id: response.id,
			chargePoint: ChargePoint.parse(response),
			price: ChargePrice.parse(response.price),
			originalPrice: originalPrice,
			type: offerType,
			campaignEndDate: Date.from(iso8601: response.campaignEndDate),
			expiresAt: expiresAt,
			signedOffer: response.signedOffer
		)
	}
}

struct ChargeOfferSchema: Decodable {
	var id: String
	var evseId: String
	var powerSpecification: PowerSpecificationSchema?
	var type: String
	var signedOffer: String
	var price: ChargePriceSchema
	var originalPrice: ChargePriceSchema?
	var campaignEndDate: String?
	var expiresAt: String

	struct PowerSpecificationSchema: Decodable {
		var type: String
		var maxPowerInKW: Double
	}
}
