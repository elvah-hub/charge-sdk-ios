// Copyright © elvah. All rights reserved.

import MapKit
import SwiftUI

@available(iOS 16.0, *)
package extension ChargePoint.Availability {
	var localizedTitle: String {
		switch self {
		case .available:
			String("Available")
		case .unavailable:
			String("Unavailable")
		case .outOfService:
			String("Out of Service")
		case .unknown:
			String("Unknown")
		}
	}

	var color: Color {
		switch self {
		case .available:
			Color.brand
		case .unavailable:
			Color.secondaryContent
		case .outOfService:
			Color.secondaryContent
		case .unknown:
			Color.secondaryContent
		}
	}
}
