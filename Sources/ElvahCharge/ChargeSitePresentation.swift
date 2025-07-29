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
	/// - Parameter chargeSite: The binding to a ``ChargeSite`` object.
	/// - Returns: A view that presents a charge site detail view using the given ``ChargeSite``
	/// object.
	@ViewBuilder func chargePresentation(
		site chargeSite: Binding<ChargeSite?>
	) -> some View {
		if #available(iOS 16.0, *) {
			modifier(PresentationViewModifier(chargeSite: chargeSite))
		} else {
			self
		}
	}
}

// MARK: - Modifiers

@available(iOS 16.0, *)
private struct PresentationViewModifier: ViewModifier {
	@Binding var chargeSite: ChargeSite?

	func body(content: Content) -> some View {
		content
			.fullScreenCover(item: $chargeSite) { chargeSite in
				ChargeOfferDetailRootFeature(
					site: chargeSite.site,
					offers: chargeSite.offers
				)
			}
	}
}
