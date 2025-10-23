// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension PowerType {
  var localizedTitle: String {
    switch self {
    case .ac:
      String(localized: "AC", bundle: .elvahCharge)

    case .dc:
      String(localized: "DC", bundle: .elvahCharge)
    }
  }
}
