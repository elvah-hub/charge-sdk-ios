// Copyright © elvah. All rights reserved.

import SwiftUI

public struct ChargeBanner: View {
	@StateObject private var router = CampaignBanner.Router()

	public var chargeSite: ChargeSite

	public var body: some View {
		Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
	}
}

package extension ChargeBanner {
	@MainActor
	final class Router: BaseRouter {
		@Published var campaignDetail: Campaign?
		@Published var showChargeSession = false

		package func reset() {
			campaignDetail = nil
			showChargeSession = false
		}
	}
}

#Preview {
	ChargeBanner(chargeSite: .mock)
}
