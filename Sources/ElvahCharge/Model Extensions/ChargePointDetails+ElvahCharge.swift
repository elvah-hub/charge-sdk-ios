// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension [ChargePoint] {
  var maxPowerInKW: Double? {
    map(\.maxPowerInKw).max()
  }
}
