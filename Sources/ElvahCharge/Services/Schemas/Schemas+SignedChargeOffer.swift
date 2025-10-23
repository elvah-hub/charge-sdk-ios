// Copyright © elvah. All rights reserved.

import Foundation

extension SignedChargeOffer {
  static func parse(
    _ response: ChargeOfferSchema,
    in site: Site,
  ) throws(NetworkError.Client) -> SignedChargeOffer {
    let chargeOffer = try ChargeOffer.parse(response, in: site)

    guard let token = response.offer.signedOffer else {
      throw .parsing(.keyPath(in: response, keyPath: \.offer.signedOffer))
    }

    guard let expiresAt = Date.from(iso8601: response.offer.expiresAt) else {
      throw .parsing(.keyPath(in: response, keyPath: \.offer.expiresAt))
    }

    return SignedChargeOffer(
      offer: chargeOffer,
      token: token,
      validUntil: expiresAt,
    )
  }

  static func parseFromSiteOffer(
    _ response: SiteOfferSchema,
    evseId: String,
  ) throws(NetworkError.Client) -> SignedChargeOffer {
    let signedOfferResponse = response.evses.first(where: { $0.evseId == evseId })
    guard let signedOfferResponse else {
      throw NetworkError.Client.parsing(
        .init(fieldName: "evses", context: "\(evseId) not found in response."),
      )
    }

    let site = try Site.parse(response)
    return try parse(signedOfferResponse, in: site)
  }
}
