// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
private extension ButtonInternal {
  struct InvertedButtonLabelKey: EnvironmentKey {
    static let defaultValue = false
  }
}

@available(iOS 16.0, *)
package extension EnvironmentValues {
  var invertedButtonLabel: Bool {
    get { self[ButtonInternal.InvertedButtonLabelKey.self] }
    set { self[ButtonInternal.InvertedButtonLabelKey.self] = newValue }
  }
}

@available(iOS 16.0, *)
package extension View {
  func invertedButtonLabel() -> some View {
    environment(\.invertedButtonLabel, true)
  }
}
