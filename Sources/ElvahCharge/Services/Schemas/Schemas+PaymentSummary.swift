// Copyright © elvah. All rights reserved.

import Foundation

extension PaymentSummary {
	static func parse(_ response: PaymentSummarySchema) throws(NetworkError) -> PaymentSummary {
		guard let sessionStartedAt = Date.from(iso8601: response.sessionStartedAt) else {
			Elvah.logger.parseError(in: response, for: \.sessionStartedAt)
			throw NetworkError.cannotParseServerResponse
		}

		guard let sessionEndedAt = Date.from(iso8601: response.sessionEndedAt) else {
			Elvah.logger.parseError(in: response, for: \.sessionEndedAt)
			throw NetworkError.cannotParseServerResponse
		}

		return PaymentSummary(
			consumedKWh: KilowattHours(response.consumedKWh),
			sessionStartedAt: sessionStartedAt,
			sessionEndedAt: sessionEndedAt,
			totalCost: Currency(
				response.totalCost.amount / 100,
				identifier: response.totalCost.currency
			)
		)
	}
}

struct PaymentSummarySchema: Decodable {
	let consumedKWh: Double
	let sessionStartedAt: String
	let sessionEndedAt: String
	let totalCost: TotalCost

	struct TotalCost: Decodable {
		let amount: Double
		let currency: String
	}
}
