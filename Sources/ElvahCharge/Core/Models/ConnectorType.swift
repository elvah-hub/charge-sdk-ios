// Copyright © elvah. All rights reserved.

import Foundation

/// A charge point's connector.
public enum ConnectorType: String, Hashable, Codable, Identifiable, Sendable, Comparable {
	case chademo = "CHADEMO"
	case combo = "COMBO"
	case other = "OTHER"
	case type2 = "TYPE_2"

	public var id: String {
		rawValue
	}

	package init(rawOrOther: String?) {
		self = .init(rawValue: rawOrOther ?? Self.other.rawValue) ?? .other
	}

	public var sortPriority: Int {
		switch self {
		case .combo:
			return 1

		case .chademo:
			return 2

		case .type2:
			return 3

		case .other:
			return 4
		}
	}

	public static func < (lhs: ConnectorType, rhs: ConnectorType) -> Bool {
		return lhs.sortPriority < rhs.sortPriority
	}
}
