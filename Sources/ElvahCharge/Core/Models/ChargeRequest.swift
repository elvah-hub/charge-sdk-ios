// Copyright © elvah. All rights reserved.

import SwiftUI

package struct ChargeRequest: Hashable, Sendable, Identifiable {
  package var id: String {
    signedOffer.chargePoint.id
  }

  package var site: Site
  package var signedOffer: SignedChargeOffer
  package var paymentContext: PaymentContext

  package init(
    site: Site,
    signedOffer: SignedChargeOffer,
    paymentContext: PaymentContext,
  ) {
    self.site = site
    self.signedOffer = signedOffer
    self.paymentContext = paymentContext
  }
}

package extension ChargeRequest {
  static var mock: ChargeRequest {
    ChargeRequest(site: .mock, signedOffer: .mockAvailable, paymentContext: .mock)
  }
}
