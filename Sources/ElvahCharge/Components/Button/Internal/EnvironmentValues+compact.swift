// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
private extension ButtonInternal {
  struct CompactControlKey: EnvironmentKey {
    static let defaultValue = false
  }
}

@available(iOS 16.0, *)
package extension EnvironmentValues {
  var isCompact: Bool {
    get { self[ButtonInternal.CompactControlKey.self] }
    set { self[ButtonInternal.CompactControlKey.self] = newValue }
  }
}

@available(iOS 16.0, *)
package extension View {
  func compactControl(_ compact: Bool = true) -> some View {
    environment(\.isCompact, compact)
  }
}
