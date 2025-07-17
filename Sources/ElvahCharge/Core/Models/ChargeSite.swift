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

	/// The cheapest available charge offer.
	public var cheapestOffer: ChargeOffer? {
		offers
			.filter(\.isAvailable)
			.sorted(using: KeyPathComparator(\.price.pricePerKWh)).first
	}
}

// MARK: - Mock Data

package extension ChargeSite {
	static var mock: ChargeSite {
		ChargeSite(site: .mock, offers: [.mockAvailable, .mockUnavailable, .mockOutOfService])
	}
}
