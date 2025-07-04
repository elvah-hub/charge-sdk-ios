// Copyright © elvah. All rights reserved.

import SwiftUI

public struct ChargePrice: Hashable, Sendable, Codable {
	public var pricePerKWh: Currency
	public var baseFee: Currency?
	public var blockingFee: BlockingFee?

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

public extension ChargePrice {
	struct BlockingFee: Hashable, Sendable, Codable {
		public var pricePerMinute: Currency
		public var startsAfterMinute: Int?

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
