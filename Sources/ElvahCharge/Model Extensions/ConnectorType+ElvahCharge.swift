// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension ConnectorType {
  var localizedTitle: String {
    switch self {
    case .chademo:
      "CHAdeMO"

    case .combo:
      "CCS"

    case .other:
      "Other"

    case .type2:
      "Type "
    }
  }
}
