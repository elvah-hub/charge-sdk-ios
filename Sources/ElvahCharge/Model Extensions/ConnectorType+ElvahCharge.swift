// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension ConnectorType {
	var localizedTitle: String {
		switch self {
		case .chademo:
			return "CHAdeMO"

		case .combo:
			return "CCS"

		case .other:
			return "Other"

		case .type2:
			return "Type "
		}
	}
}
