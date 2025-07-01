// Copyright © elvah. All rights reserved.

import MapKit
import SwiftUI

/// A wrapper view around ``ChargeOfferList`` that adds a `NavigationStack` and all required
/// environment objects.
@available(iOS 16.0, *)
package struct ChargeOfferListWrapperFeature: View {
	@StateObject private var router = ChargeOfferListWrapperFeature.Router()
	private var site: Site?
	private var deals: [Deal]

	package init(site: Site, deals: [Deal] = []) {
		self.site = site
		self.deals = deals
	}

	@State private var show = false

	package var body: some View {
		NavigationStack(path: $router.path) {
			ChargeOfferListFeature(deals: deals, router: router.chargeOfferListRouter)
				.siteInformation(site)
		}
		.navigationRoot(path: $router.path)
		.withEnvironmentObjects()
	}
}

@available(iOS 16.0, *)
package extension ChargeOfferListWrapperFeature {
	@MainActor
	final class Router: BaseRouter {
		@Published var path = NavigationPath()

		let chargeOfferListRouter = ChargeOfferListFeature.Router()

		package func reset() {
			path = NavigationPath()
			chargeOfferListRouter.reset()
		}
	}
}
