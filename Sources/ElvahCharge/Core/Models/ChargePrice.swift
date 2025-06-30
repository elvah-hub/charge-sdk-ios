// Copyright © elvah. All rights reserved.

import SwiftUI

package struct ChargePrice: Hashable, Sendable, Codable {
	package var pricePerKWh: Currency
	package var baseFee: Currency?
	package var blockingFee: BlockingFee?

	package init(
		pricePerKWh: Currency,
		baseFee: Currency? = nil,
		blockingFee: BlockingFee? = nil
	) {
		self.pricePerKWh = pricePerKWh
		self.baseFee = baseFee
		self.blockingFee = blockingFee
	}
}

package extension ChargePrice {
	struct BlockingFee: Hashable, Sendable, Codable {
		package var pricePerMinute: Currency
		package var startsAfterMinute: Int?

		package init(of pricePerMinute: Currency, startingAfter startsAfterMinute: Int? = nil) {
			self.pricePerMinute = pricePerMinute
			self.startsAfterMinute = startsAfterMinute
		}
	}
}

package extension ChargePrice {
	static var mock: ChargePrice {
		ChargePrice(
			pricePerKWh: Currency(0.42),
			baseFee: Currency(1.42),
			blockingFee: ChargePrice.BlockingFee(of: Currency(0.42), startingAfter: 10)
		)
	}
}
