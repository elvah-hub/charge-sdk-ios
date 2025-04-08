// Copyright © elvah. All rights reserved.

import Foundation

package enum Radius {
	case XL // 24
	case L // 16
	case M // 12
	case S // 8
	case XS // 4
	case zero // Zero size.

	/// The size value of the given size classes.
	package var size: CGFloat {
		switch self {
		case .XL: 24
		case .L: 16
		case .M: 12
		case .S: 8
		case .XS: 4
		case .zero: 0
		}
	}
}
