// Copyright © elvah. All rights reserved.

import SwiftUI

/// The pricing information associated with a ``ChargeOffer``.
public struct ChargePrice: Hashable, Sendable, Codable {
	/// The cost per kilowatt-hour of energy consumed.
	public var pricePerKWh: Currency

	/// An optional base fee charged at the start of the charging session.
	public var baseFee: Currency?

	/// An optional fee structure for occupying the charging point beyond the charging period.
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
	/// The fee structure for blocking a charging point after charging is complete.
	struct BlockingFee: Hashable, Sendable, Codable {
		/// The cost per minute for blocking the charging point.
		public var pricePerMinute: Currency

		/// The grace period in minutes before blocking fees begin to apply.
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

	static var mock2: ChargePrice {
		ChargePrice(
			pricePerKWh: Currency(0.53),
			baseFee: Currency(1.12),
			blockingFee: ChargePrice.BlockingFee(of: Currency(0.62), startingAfter: 0)
		)
	}

	static var mock3: ChargePrice {
		ChargePrice(
			pricePerKWh: Currency(0.71),
			baseFee: Currency(1.62),
			blockingFee: ChargePrice.BlockingFee(of: Currency(0.12), startingAfter: 20)
		)
	}
}
