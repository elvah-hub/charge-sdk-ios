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

	package var site: Site
	package var offers: [ChargeOffer]

	package init(site: Site, offers: [ChargeOffer]) {
		self.site = site
		self.offers = offers
	}

	public subscript<V>(dynamicMember keyPath: WritableKeyPath<Site, V>) -> V {
		get { site[keyPath: keyPath] }
		set { site[keyPath: keyPath] = newValue }
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

	/// The offer that expires the latest among all offers in the campaign.
	var latestEndingOffer: ChargeOffer? {
		offers.filter { $0.hasEnded == false }.sorted(using: KeyPathComparator(\.campaignEndDate)).last
	}

	/// The offer that expires the earliest among all offers in the campaign.
	var earliestEndingOffer: ChargeOffer? {
		offers.filter { $0.hasEnded == false }.sorted(using: KeyPathComparator(\.campaignEndDate)).first
	}
}

// MARK: - Mock Data

package extension ChargeSite {
	static var mock: ChargeSite {
		ChargeSite(site: .mock, offers: [.mockAvailable, .mockUnavailable, .mockOutOfService])
	}
}
