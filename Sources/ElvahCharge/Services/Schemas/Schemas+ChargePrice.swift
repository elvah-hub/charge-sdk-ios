// Copyright © elvah. All rights reserved.

import Foundation

extension ChargePrice {
	static func parse(_ response: ChargePriceSchema) throws(NetworkError.Client) -> ChargePrice {
		var blockingFee: ChargePrice.BlockingFee? {
			guard let blockingFee = response.blockingFee else {
				return nil
			}

			return ChargePrice.BlockingFee(
				of: Currency(blockingFee.pricePerMinute, identifier: response.currency),
				startingAfter: response.blockingFee?.startsAfterMinutes
			)
		}

		var baseFee: Currency? {
			guard let baseFee = response.baseFee else {
				return nil
			}
			return Currency(baseFee, identifier: response.currency)
		}

		return ChargePrice(
			pricePerKWh: Currency(response.energyPricePerKWh, identifier: response.currency),
			baseFee: baseFee,
			blockingFee: blockingFee
		)
	}
}

struct ChargePriceSchema: Decodable {
	var energyPricePerKWh: Double
	var baseFee: Double?
	var blockingFee: BlockingFeeSchema?
	var currency: String

	struct BlockingFeeSchema: Decodable {
		var pricePerMinute: Double
		var startsAfterMinutes: Int?
	}
}
