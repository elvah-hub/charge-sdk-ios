// Copyright © elvah. All rights reserved.

import SwiftUI

/// A charge point with attached and signed pricing information.
@dynamicMemberLookup
package struct SignedChargeOffer: Codable, Hashable, Identifiable, Sendable {
  package var id: String {
    offer.id
  }

  /// The underlying charge offer.
  package var offer: ChargeOffer

  /// The agreement to charge under the pricing conditions of the associated charge offer.
  package var token: String

  /// The date at which the conditions of the offer might change.
  public var validUntil: Date

  package init(
    offer: ChargeOffer,
    token: String,
    validUntil: Date,
  ) {
    self.offer = offer
    self.token = token
    self.validUntil = validUntil
  }

  public subscript<V>(dynamicMember keyPath: KeyPath<ChargeOffer, V>) -> V {
    offer[keyPath: keyPath]
  }

  public subscript<V>(dynamicMember keyPath: WritableKeyPath<ChargeOffer, V>) -> V {
    get { offer[keyPath: keyPath] }
    set { offer[keyPath: keyPath] = newValue }
  }

  /// A flag indicating if the offer is still available.
  ///
  /// This flag will always be `true` for offers that are not part of a campaign.
  /// - Note: This is different from ``ChargeOffer/validUntil``, which notes the date at
  /// which the conditions of the offer might change.
  public var isAvailable: Bool {
    offer.isAvailable
  }
}

package extension SignedChargeOffer {
  static var mockAvailable: SignedChargeOffer {
    SignedChargeOffer(
      offer: .mockAvailable,
      token: "",
      validUntil: Date().addingTimeInterval(120),
    )
  }

  static var mockUnavailable: SignedChargeOffer {
    SignedChargeOffer(
      offer: .mockUnavailable,
      token: "",
      validUntil: Date().addingTimeInterval(120),
    )
  }

  static var mockOutOfService: SignedChargeOffer {
    SignedChargeOffer(
      offer: .mockOutOfService,
      token: "",
      validUntil: Date().addingTimeInterval(120),
    )
  }
}

package extension [SignedChargeOffer] {
  var cheapestOffer: SignedChargeOffer? {
    sorted(using: KeyPathComparator(\.offer.price.pricePerKWh)).first
  }
}
