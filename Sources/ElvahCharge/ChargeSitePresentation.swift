// Copyright © elvah. All rights reserved.

import SwiftUI

public extension View {
  /// Presents a modal view showing a charge site detail view where users can start a new in-app
  /// charge session. Its presentation is controlled by the provided binding to a ``ChargeSite``
  /// object.
  ///
  /// You can fetch a ``ChargeSite`` object by calling ``ChargeSite/sites(in:)`` or
  /// one of its adjacent methods.
  /// - Important: This modifier requires iOS 16.0 or later. On earlier versions, it does nothing to
  /// the wrapped view.
  /// - Parameters:
  ///   - chargeSite: The binding to a ``ChargeSite`` object.
  ///   - options: Presentation configuration options. Default is empty set.
  /// - Returns: A view that presents a charge site detail view using the given ``ChargeSite``
  /// object.
  @ViewBuilder func chargePresentation(
    site chargeSite: Binding<ChargeSite?>,
    options: ChargePresentationOptions = [],
  ) -> some View {
    if #available(iOS 16.0, *) {
      modifier(PresentationViewModifier(chargeSite: chargeSite, options: options))
    } else {
      self
    }
  }
}

// MARK: - Modifiers

@available(iOS 16.0, *)
private struct PresentationViewModifier: ViewModifier {
  @Binding var chargeSite: ChargeSite?
  var options: ChargePresentationOptions = []

  func body(content: Content) -> some View {
    content
      .fullScreenCover(item: $chargeSite) { chargeSite in
        ChargeOfferDetailRootFeature(
          site: chargeSite.site,
          offers: chargeSite.offers,
          options: options,
        )
      }
  }
}
