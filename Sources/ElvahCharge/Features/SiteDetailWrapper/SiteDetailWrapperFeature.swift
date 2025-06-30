// Copyright © elvah. All rights reserved.

import MapKit
import SwiftUI

/// A wrapper view around ``SiteDetailFeature`` that adds a `NavigationStack` and all required
/// environment objects.
@available(iOS 16.0, *)
package struct SiteDetailWrapperFeature: View {
	@StateObject private var router = SiteDetailWrapperFeature.Router()
	private var site: Site
	private var deals: [Deal]

	package init(site: Site, deals: [Deal] = []) {
		self.site = site
		self.deals = deals
	}

	@State private var show = false

	package var body: some View {
		NavigationStack(path: $router.path) {
			ChargePointListView(deals: deals, router: router.siteDetailRouter)
				.siteInformation(site)
		}
		.navigationRoot(path: $router.path)
		.withEnvironmentObjects()
	}
}

@available(iOS 16.0, *)
package extension SiteDetailWrapperFeature {
	@MainActor
	final class Router: BaseRouter {
		@Published var path = NavigationPath()

		let siteDetailRouter = ChargePointListView.Router()

		package func reset() {
			path = NavigationPath()
			siteDetailRouter.reset()
		}
	}
}
