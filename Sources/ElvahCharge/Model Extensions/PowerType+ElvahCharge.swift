// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension PowerType {
	var localizedTitle: String {
		switch self {
		case .ac:
			return String(localized: "AC", bundle: .elvahCharge)

		case .dc:
			return String(localized: "DC", bundle: .elvahCharge)
		}
	}
}
