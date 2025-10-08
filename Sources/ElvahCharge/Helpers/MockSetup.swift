// Copyright © elvah. All rights reserved.

import SwiftUI

enum PreviewLanguage: String {
  case english = "en"
  case german = "de"
}

@available(iOS 16.0, *)
extension View {
  func withMockEnvironmentObjects(language: PreviewLanguage = .english) -> some View {
    environmentObject(ChargeSettlementProvider.mock)
      .environmentObject(DiscoveryProvider.mock)
      .environmentObject(ChargeProvider.mock)
      .environment(\.locale, .init(identifier: language.rawValue))
  }
}
