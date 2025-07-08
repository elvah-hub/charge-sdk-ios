// Copyright © elvah. All rights reserved.

import SwiftUI

public extension View {
	/// Presents a modal view showing a charge offer detail view where users can start a new in-app
	/// charge
	/// session. Its presentation is controlled by the provided binding to a ``ChargeOfferList`` object.
	///
	/// You can fetch a ``ChargeOfferList`` object by calling ``ChargeOffer/offers(forEvseId:)``
	/// or one of its adjacent methods.
	/// - Important: This modifier requires iOS 16.0 or later. On earlier versions, it does nothing to
	/// the wrapped view.
	/// - Returns: A view that presents a campaign detail view using the given ``ChargeOffer`` object.
	@ViewBuilder func chargeOfferDetailPresentation(
		for chargeOffers: Binding<ChargeOfferList?>,
	) -> some View {
		if #available(iOS 16.0, *) {
			modifier(PresentationViewModifier(chargeOfferList: chargeOffers))
		} else {
			self
		}
	}
}

// MARK: - Modifiers

@available(iOS 16.0, *)
private struct PresentationViewModifier: ViewModifier {
	@Binding var chargeOfferList: ChargeOfferList?

	func body(content: Content) -> some View {
		content
			.fullScreenCover(item: $chargeOfferList) { chargeOfferList in
				ChargeOfferDetailRootFeature(
					site: nil,
					offers: chargeOfferList.offers
				)
			}
	}
}
