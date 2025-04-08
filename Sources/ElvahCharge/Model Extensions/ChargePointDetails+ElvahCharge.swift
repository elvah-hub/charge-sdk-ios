// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension ChargePointDetails {
	/// Returns a user-facing label that can be used to describe the chargePoint's availability.
	var localizedAvailability: String {
		if isOccupied {
			return String(localized: "Occupied", bundle: .elvahCharge)
		}

		if isOutOfService {
			return String(localized: "Out of service", bundle: .elvahCharge)
		}

		return String(localized: "Available now", bundle: .elvahCharge)
	}
}

@available(iOS 16.0, *)
package extension [ChargePointDetails] {
	var maxPowerInKW: Double? {
		map(\.maxPowerInKw).max()
	}
}
