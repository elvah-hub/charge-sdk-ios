// Copyright © elvah. All rights reserved.

import Foundation

/// A charge point's connector.
public enum PowerType: String, Hashable, Codable, Identifiable, Sendable, Comparable {
	case ac = "AC"
	case dc = "DC"

	public var id: String {
		rawValue
	}

	package var sortPriority: Int {
		switch self {
		case .ac:
			return 1

		case .dc:
			return 2
		}
	}

	public static func < (lhs: PowerType, rhs: PowerType) -> Bool {
		return lhs.sortPriority < rhs.sortPriority
	}
}
