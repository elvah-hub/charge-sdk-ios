// Copyright © elvah. All rights reserved.

import Foundation

/// A charge point's connector.
public enum PowerType: String, Hashable, Codable, Identifiable, Sendable, Comparable {
  /// The AC power type.
  case ac = "AC"

  /// The DC power type.
  case dc = "DC"

  public var id: String {
    rawValue
  }

  package var sortPriority: Int {
    switch self {
    case .ac:
      1

    case .dc:
      2
    }
  }

  public static func < (lhs: PowerType, rhs: PowerType) -> Bool {
    lhs.sortPriority < rhs.sortPriority
  }
}
