// Copyright © elvah. All rights reserved.

import SwiftUI

@dynamicMemberLookup
package struct SignedChargeOffer: Codable, Hashable, Identifiable, Sendable {
	package var id: String {
		offer.id
	}

	package var offer: ChargeOffer
	package var signedOffer: String

	package init(offer: ChargeOffer, signedOffer: String) {
		self.offer = offer
		self.signedOffer = signedOffer
	}

	public subscript<V>(dynamicMember keyPath: WritableKeyPath<ChargeOffer, V>) -> V {
		get { offer[keyPath: keyPath] }
		set { offer[keyPath: keyPath] = newValue }
	}}

package extension SignedChargeOffer {
	static var mockAvailable: SignedChargeOffer {
		SignedChargeOffer(offer: .mockAvailable, signedOffer: "")
	}

	static var mockUnavailable: SignedChargeOffer {
		SignedChargeOffer(offer: .mockUnavailable, signedOffer: "")
	}

	static var mockOutOfService: SignedChargeOffer {
		SignedChargeOffer(offer: .mockOutOfService, signedOffer: "")
	}
}

package extension [SignedChargeOffer] {
	var cheapestOffer: SignedChargeOffer? {
		sorted(using: KeyPathComparator(\.offer.price.pricePerKWh)).first
	}

	var earliestEndingOffer: SignedChargeOffer? {
		sorted(using: KeyPathComparator(\.offer.price.pricePerKWh)).first
	}
}
