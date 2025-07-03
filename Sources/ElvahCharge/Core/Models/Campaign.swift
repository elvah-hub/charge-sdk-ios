// Copyright © elvah. All rights reserved.

import SwiftUI

public struct Campaign: Identifiable, Hashable, Codable, Sendable {
	public var id: String { site.id }
	package var site: Site
	package var deals: [Deal]

	package init(site: Site, deals: [Deal]) {
		self.site = site
		self.deals = deals
	}

	/// The date at which the last deal of the campaign expires.
	public var endDate: Date {
		// There should always be a cheapest deal, so the fallback should never occur.
		latestEndingDeal?.campaignEndDate ?? .distantFuture
	}

	public var hasEnded: Bool {
		endDate < Date()
	}
}

// MARK: - Helpers

package extension Campaign {
	/// The cheapest, non-expired deal in the campaign.
	var cheapestDeal: Deal? {
		deals.filter { $0.hasEnded == false }.sorted(using: KeyPathComparator(\.pricePerKWh)).first
	}

	/// The deal that expires the latest among all deals in the campaign.
	var latestEndingDeal: Deal? {
		deals.filter { $0.hasEnded == false }.sorted(using: KeyPathComparator(\.campaignEndDate)).last
	}

	/// The deal that expires the earliest among all deals in the campaign.
	var earliestEndingDeal: Deal? {
		deals.filter { $0.hasEnded == false }.sorted(using: KeyPathComparator(\.campaignEndDate)).first
	}
}

// MARK: - Mock Data

package extension Campaign {
	static var mock: Campaign {
		Campaign(site: .mock, deals: [.mockAvailable, .mockUnavailable, .mockOutOfService])
	}
}
