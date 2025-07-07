// Copyright © elvah. All rights reserved.

import SwiftUI

/// A ``ChargeSite`` whose offers are all part of a campaign.
public struct Campaign: Identifiable, Hashable, Codable, Sendable {
	public var id: String { chargeSite.id }
	public var chargeSite: ChargeSite

	package init(chargeSite: ChargeSite) {
		self.chargeSite = chargeSite
	}

	/// Returns the end date of the campaign for a given charge offer.
	/// - Parameter chargeOffer: The charge offer. This must be part of the campaign's charge site.
	/// - Returns: The end date of the campaign.
	public func endDate(for chargeOffer: ChargeOffer) -> Date {
		chargeOffer.campaignInfo?.endDate ?? .distantPast
	}

	/// A flag indicating whether the last charge offer part of this campaign has ended.
	///
	/// - Important: The end date of a charge offer's campaign is distinctly different from its expiry date.
	/// The latter is only tied to the offered pricing and does not reflect the campaign's duration.
	/// - Note: Usually, all charge offers within a campaign end at the same time.
	public var hasEnded: Bool {
		latestEndingChargeOffer?.hasEnded ?? true
	}

	/// The charge offer that ends the latest among all offers in the campaign.
	///
	/// - Important: The end date of a charge offer's campaign is distinctly different from its expiry date.
	/// The latter is only tied to the offered pricing and does not reflect the campaign's duration.
	/// - Note: Usually, all charge offers within a campaign end at the same time.
	public var latestEndingChargeOffer: ChargeOffer? {
		chargeSite.offers
			.filter { $0.hasEnded == false }
			.sorted(using: KeyPathComparator(\.campaignInfo?.endDate)).last
	}

	/// The charge offer that ends the earliest among all offers in the campaign.
	///
	/// - Important: The end date of a charge offer's campaign is distinctly different from its expiry date.
	/// The latter is only tied to the offered pricing and does not reflect the campaign's duration.
	/// - Note: Usually, all charge offers within a campaign end at the same time.
	public var earliestEndingChargeOffer: ChargeOffer? {
		chargeSite.offers
			.filter { $0.hasEnded == false }
			.sorted(using: KeyPathComparator(\.campaignInfo?.endDate)).first
	}
}

// MARK: - Mock Data

package extension Campaign {
	static var mock: Campaign {
		Campaign(chargeSite: .mock)
	}
}
