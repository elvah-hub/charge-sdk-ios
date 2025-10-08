// Copyright © elvah. All rights reserved.

import SwiftUI

private struct ProgressRingTintKey: EnvironmentKey {
  static let defaultValue: Color? = nil
}

extension EnvironmentValues {
  var progressRingTint: Color? {
    get { self[ProgressRingTintKey.self] }
    set { self[ProgressRingTintKey.self] = newValue }
  }
}

extension View {
  func progressRingTint(_ color: Color?) -> some View {
    environment(\.progressRingTint, color)
  }
}
