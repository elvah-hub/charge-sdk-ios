// Copyright © elvah. All rights reserved.

import Foundation

package struct StripeConfiguration: Hashable, Sendable {
	package var publishableKey: String

	package init(publishableKey: String) {
		self.publishableKey = publishableKey
	}
}
