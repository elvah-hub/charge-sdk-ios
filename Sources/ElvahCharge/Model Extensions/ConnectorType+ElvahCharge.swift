// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension ConnectorType {
	var localizedTitle: String {
		switch self {
		case .chademo:
			return String(localized: "CHAdeMO", bundle: .elvahCharge)

		case .combo:
			return String(localized: "CCS", bundle: .elvahCharge)

		case .other:
			return String(localized: "Other", bundle: .elvahCharge)

		case .type2:
			return String(localized: "Type 2", bundle: .elvahCharge)
		}
	}
}
