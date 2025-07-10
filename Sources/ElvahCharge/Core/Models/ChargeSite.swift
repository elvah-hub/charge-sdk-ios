// Copyright © elvah. All rights reserved.

import CoreLocation
import SwiftUI

/// A place with one or more charge points to charge an electric car at.
///
/// This is a wrapper around ``Site`` that adds accessible charge offers for each charge point.
@dynamicMemberLookup
public struct ChargeSite: Codable, Hashable, Identifiable, Sendable {
	public var id: String {
		site.id
	}

	/// The underlying site.
	package var site: Site

	/// The underlying site's charge offers.
	package var offers: [ChargeOffer]

	package init(site: Site, offers: [ChargeOffer]) {
		self.site = site
		self.offers = offers
	}

	public subscript<V>(dynamicMember keyPath: WritableKeyPath<Site, V>) -> V {
		get { site[keyPath: keyPath] }
		set { site[keyPath: keyPath] = newValue }
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
		offers
			.filter { $0.hasEnded == false }
			.sorted(using: KeyPathComparator(\.campaignInfo?.endDate)).last
	}

	/// The charge offer that ends the earliest among all offers in the campaign.
	///
	/// - Important: The end date of a charge offer's campaign is distinctly different from its expiry date.
	/// The latter is only tied to the offered pricing and does not reflect the campaign's duration.
	/// - Note: Usually, all charge offers within a campaign end at the same time.
	public var earliestEndingChargeOffer: ChargeOffer? {
		offers
			.filter { $0.hasEnded == false }
			.sorted(using: KeyPathComparator(\.campaignInfo?.endDate)).first
	}
}

// MARK: - Helpers

package extension ChargeSite {
	/// The cheapest, non-expired offer in the campaign.
	var cheapestOffer: ChargeOffer? {
		offers
			.filter { $0.hasEnded == false }
			.sorted(using: KeyPathComparator(\.price.pricePerKWh)).first
	}
}

// MARK: - Mock Data

package extension ChargeSite {
	static var mock: ChargeSite {
		ChargeSite(site: .mock, offers: [.mockAvailable, .mockUnavailable, .mockOutOfService])
	}
}
