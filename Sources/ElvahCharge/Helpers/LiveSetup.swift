// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension View {
	@MainActor func withEnvironmentObjects() -> some View {
		environmentObject(ChargeSettlementProvider.live)
			.environmentObject(ChargeProvider.live)
			.environmentObject(DiscoveryProvider.live)
	}
}
