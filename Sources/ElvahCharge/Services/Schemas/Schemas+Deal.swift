// Copyright © elvah. All rights reserved.

import Foundation

extension Deal {
	static func parse(_ response: DealSchema) throws(NetworkError) -> Deal {
		guard let campaignEndDate = Date.from(iso8601: response.campaignEndDate) else {
			Elvah.logger.parseError(in: response, for: \.campaignEndDate)
			throw NetworkError.cannotParseServerResponse
		}

		guard let expiresAt = Date.from(iso8601: response.expiresAt) else {
			Elvah.logger.parseError(in: response, for: \.expiresAt)
			throw NetworkError.cannotParseServerResponse
		}

		return try Deal(
			id: response.id,
			chargePoint: ChargePoint.parse(response),
			pricePerKWh: Currency(response.pricePerKWh, identifier: response.currency),
			securityDeposit: nil,
			campaignEndDate: campaignEndDate,
			expiresAt: expiresAt,
			signedDeal: response.signedDeal
		)
	}
}

struct DealSchema: Decodable {
	var id: String
	var evseId: String
	var normalizedEvseId: String
	var powerSpecification: PowerSpecification?
	var pricePerKWh: Double
	var currency: String
	var campaignEndDate: String
	var expiresAt: String
	var signedDeal: String

	struct PowerSpecification: Decodable {
		var type: String
		var maxPowerInKW: Double
	}
}
