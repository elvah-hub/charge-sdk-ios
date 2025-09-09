// Copyright © elvah. All rights reserved.

import MapKit
import SwiftUI

/// A root view around ``ChargeOfferList`` that adds a `NavigationStack` and all required
/// environment objects.
@available(iOS 16.0, *)
package struct ChargeOfferDetailRootFeature: View {
  @StateObject private var router = ChargeOfferDetailRootFeature.Router()
  private var site: Site?
	private var offers: [ChargeOffer]
  private var options: ChargePresentationOptions = []

	package init(site: Site?, offers: [ChargeOffer] = [], options: ChargePresentationOptions = []) {
    self.site = site
    self.offers = offers
    self.options = options
  }

  @State private var show = false

  package var body: some View {
    NavigationStack(path: $router.path) {
      ChargeOfferDetailFeature(
        offers: offers,
        router: router.chargeOfferListRouter,
        hideOperatorDetails: options.contains(.hideOperatorDetails),
        hideDiscountBanner: options.contains(.hideDiscountBanner)
      )
        .siteInformation(site)
    }
    .navigationRoot(path: $router.path)
    .withEnvironmentObjects()
  }
}

@available(iOS 16.0, *)
package extension ChargeOfferDetailRootFeature {
  final class Router: BaseRouter {
    @Published var path = NavigationPath()

    let chargeOfferListRouter = ChargeOfferDetailFeature.Router()

    package func reset() {
      path = NavigationPath()
      chargeOfferListRouter.reset()
    }
  }
}
