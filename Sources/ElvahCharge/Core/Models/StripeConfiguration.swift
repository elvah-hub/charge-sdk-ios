// Copyright © elvah. All rights reserved.

import Foundation

package struct StripeConfiguration: Hashable, Sendable, Codable {
	package var publishableKey: String

	package init(publishableKey: String) {
		self.publishableKey = publishableKey
	}
}

package extension StripeConfiguration {
	static var simulation: StripeConfiguration {
		return StripeConfiguration(publishableKey: "sk_test_42")
	}
}
