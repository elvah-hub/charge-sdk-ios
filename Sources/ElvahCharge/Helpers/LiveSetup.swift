// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension View {
  func withEnvironmentObjects() -> some View {
    environmentObject(
      Elvah.configuration.environment.isSimulation
        ? ChargeSettlementProvider.simulation
        : .live,
    )
    .environmentObject(
      Elvah.configuration.environment.isSimulation
        ? ChargeProvider.simulation
        : .live,
    )
    .environmentObject(
      Elvah.configuration.environment.isSimulation
        ? DiscoveryProvider.simulation
        : .live,
    )
  }
}
