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

	public var hasAdditionalCost: Bool {
		baseFee != nil || blockingFee != nil
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

	/// Creates a randomized charge price around a base price with optional variation.
	/// - Parameters:
	///   - basePrice: The base price per kWh in EUR
	///   - variation: The maximum variation from the base price (default: 0.10)
	/// - Returns: A charge price with randomized values
	static func randomizedPrice(
		around basePrice: Double = 0.59,
		variation: Double = 0.10
	) -> ChargePrice {
		let priceVariation = Double.random(in: -variation ... variation)
		let finalPrice = max(0.20, basePrice + priceVariation) // Ensure minimum reasonable price

		let baseFees = [nil, Currency(0.50), Currency(1.00), Currency(1.50), Currency(2.00)]
		let randomBaseFee = baseFees.randomElement()!

		let blockingFeePrice = Currency(Double.random(in: 0.10 ... 0.80))
		let gracePeriod = [0, 5, 10, 15, 30].randomElement()!
		let blockingFee = ChargePrice.BlockingFee(of: blockingFeePrice, startingAfter: gracePeriod)

		return ChargePrice(
			pricePerKWh: Currency(finalPrice),
			baseFee: randomBaseFee,
			blockingFee: Bool.random() ? blockingFee : nil
		)
	}

	/// Creates a campaign price that's discounted from a base price.
	/// - Parameter basePrice: The original base price to discount from
	/// - Returns: A discounted ChargePrice for campaign offers
	static func campaignPrice(from basePrice: ChargePrice) -> ChargePrice {
		let discountPercentage = Double.random(in: 0.10 ... 0.30) // 10-30% discount
		let discountedPrice = basePrice.pricePerKWh.amount * (1 - discountPercentage)

		return ChargePrice(
			pricePerKWh: Currency(discountedPrice),
			baseFee: basePrice.baseFee,
			blockingFee: basePrice.blockingFee
		)
	}
}
