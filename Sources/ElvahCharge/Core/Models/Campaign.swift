// Copyright © elvah. All rights reserved.

import SwiftUI

public struct Campaign: Identifiable, Hashable, Codable, Sendable {
	public var id: String { chargeSite.id }
	package var chargeSite: ChargeSite

	package init(chargeSite: ChargeSite) {
		self.chargeSite = chargeSite
	}

	public var endDate: Date {
		// There should always be a cheapest offer, so the fallback should never occur.
		chargeSite.latestEndingOffer?.campaignEndDate ?? .distantFuture
	}

	public var hasEnded: Bool {
		endDate < Date()
	}

}

// MARK: - Mock Data

package extension Campaign {
	static var mock: Campaign {
		Campaign(chargeSite: .mock)
	}
}
