// Copyright © elvah. All rights reserved.

import SwiftUI

package struct Deal: Codable, Hashable, Identifiable, Sendable {
	package var id: String

	package var evseId: String {
		chargePoint.evseId
	}

	package var chargePoint: ChargePointDetails
	package var pricePerKWh: Currency
	package var securityDeposit: Currency?
	package var campaignEndDate: Date
	package var expiresAt: Date
	package var signedDeal: String

	package init(
		id: String,
		chargePoint: ChargePointDetails,
		pricePerKWh: Currency,
		securityDeposit: Currency?,
		campaignEndDate: Date,
		expiresAt: Date,
		signedDeal: String
	) {
		self.id = id
		self.chargePoint = chargePoint
		self.pricePerKWh = pricePerKWh
		self.securityDeposit = securityDeposit
		self.campaignEndDate = campaignEndDate
		self.expiresAt = expiresAt
		self.signedDeal = signedDeal
	}

	/// Returns `true` if the associated campaign has ended, `false` otherwise.
	package var hasEnded: Bool {
		campaignEndDate < Date()
	}
}

package extension Deal {
	static var mockAvailable: Deal {
		Deal(
			id: "mock deal available",
			chargePoint: .mockAvailable,
			pricePerKWh: 0.42,
			securityDeposit: nil,
			campaignEndDate: Date().addingTimeInterval(20),
			expiresAt: Date().addingTimeInterval(120),
			signedDeal: "mock deal"
		)
	}

	static var mockUnavailable: Deal {
		Deal(
			id: "mock deal unavailable",
			chargePoint: .mockUnavailable,
			pricePerKWh: 0.38,
			securityDeposit: nil,
			campaignEndDate: Date().addingTimeInterval(-10),
			expiresAt: Date().addingTimeInterval(120),
			signedDeal: "mock deal"
		)
	}

	static var mockOutOfService: Deal {
		Deal(
			id: "mock deal out of service",
			chargePoint: .mockOutOfService,
			pricePerKWh: 0.56,
			securityDeposit: nil,
			campaignEndDate: Date().addingTimeInterval(30),
			expiresAt: Date().addingTimeInterval(120),
			signedDeal: "mock deal"
		)
	}
}

package extension [Deal] {
	var cheapestDeal: Deal? {
		sorted(using: KeyPathComparator(\.pricePerKWh)).first
	}

	var earliestEndingDeal: Deal? {
		sorted(using: KeyPathComparator(\.campaignEndDate)).first
	}
}
