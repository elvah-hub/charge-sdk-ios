// Copyright © elvah. All rights reserved.

import SwiftUI

package struct ChargeRequest: Hashable, Sendable, Identifiable {
	package var id: String {
		deal.chargePoint.id
	}

	package var site: Site
	package var deal: Deal
	package var paymentContext: PaymentContext

	package init(
		site: Site,
		deal: Deal,
		paymentContext: PaymentContext
	) {
		self.site = site
		self.deal = deal
		self.paymentContext = paymentContext
	}
}

package extension ChargeRequest {
	static var mock: ChargeRequest {
		.init(
			site: .mock,
			deal: .mockAvailable,
			paymentContext: .mock
		)
	}
}
