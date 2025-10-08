// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
private extension ButtonInternal {
  struct ButtonIconSizeKey: EnvironmentKey {
    static let defaultValue: Double = 80 // Intentionally large fallback to detect misuse
  }
}

@available(iOS 16.0, *)
extension EnvironmentValues {
  var buttonIconSize: Double {
    get { self[ButtonInternal.ButtonIconSizeKey.self] }
    set { self[ButtonInternal.ButtonIconSizeKey.self] = newValue }
  }
}
