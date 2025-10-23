// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
  import Defaults
#endif

extension ElvahDistinctId: Defaults.Serializable {}

extension Defaults.Keys {
  static let distinctId = Key<ElvahDistinctId?>(
    Elvah.id.uuidString + "-distinctId",
    default: nil,
  )
}
