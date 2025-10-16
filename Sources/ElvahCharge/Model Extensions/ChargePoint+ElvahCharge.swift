// Copyright © elvah. All rights reserved.

import MapKit
import SwiftUI

@available(iOS 16.0, *)
package extension ChargePoint.Availability {
  var localizedTitle: String {
    switch self {
    case .available:
      String(localized: "Available", bundle: .elvahCharge)
    case .unavailable:
      String(localized: "Occupied", bundle: .elvahCharge)
    case .outOfService:
      String(localized: "Out of service", bundle: .elvahCharge)
    case .unknown:
      String(localized: "Unknown", bundle: .elvahCharge)
    }
  }

  var color: Color {
    switch self {
    case .available:
      Color.brand
    case .unavailable:
      Color.secondaryContent
    case .outOfService:
      Color.secondaryContent
    case .unknown:
      Color.secondaryContent
    }
  }
}
