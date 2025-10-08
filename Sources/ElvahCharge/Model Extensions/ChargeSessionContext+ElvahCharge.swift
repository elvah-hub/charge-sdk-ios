// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
  import Defaults
#endif

extension ChargeSessionContext: Defaults.Serializable {}

extension Defaults.Keys {
  static let chargeSessionContext = Key<ChargeSessionContext?>(
    Elvah.id.uuidString + "-chargeSessionContext",
    default: nil,
  )
}
