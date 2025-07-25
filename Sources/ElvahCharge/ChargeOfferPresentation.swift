// Copyright © elvah. All rights reserved.

import SwiftUI

public extension View {
	/// Presents a modal view that handles payment and charging for a specific charge point.
	/// Whenever the provided `chargeOffer` parameter holds a value, a presentation is triggered that
	/// offers the user to pay and start charging.
	///
	/// You can use modifier if you are building custom UI components and want to skip the pre-built
	/// site detail screen that this SDK comes with.
	///
	/// - Important: This modifier requires iOS 16.0 or later. On earlier versions, it does nothing to
	/// the wrapped view.
	/// - Parameters:
	///   - chargeOffer: The charge offer that should be resolved. This must be part of the provided
	/// charge site.
	/// - Returns: A view that presents a modal that handles payment and charging for a specific
	/// charge point.
	@ViewBuilder func chargePresentation(offer chargeOffer: Binding<ChargeOffer?>) -> some View {
		if #available(iOS 16.0, *) {
			modifier(PresentationViewModifier(chargeOffer: chargeOffer))
		} else {
			self
		}
	}

	/// Presents a modal view showing a charge offer detail view where users can start a new in-app
	/// charge session. Its presentation is controlled by the provided binding to a
	/// ``ChargeOfferList`` object.
	///
	/// The modifier checks if all offers have the same site. If they do, the site information
	/// is passed to the detail feature. If offers are from different sites, no site information
	/// is provided.
	/// - Important: This modifier requires iOS 16.0 or later. On earlier versions, it does nothing to
	/// the wrapped view.
	/// - Parameter chargeOfferList: The binding to a ``ChargeOfferList`` object.
	/// - Returns: A view that presents a charge offer detail view using the given
	/// ``ChargeOfferList``.
	@ViewBuilder func chargePresentation(
		offers chargeOfferList: Binding<ChargeOfferList?>
	) -> some View {
		if #available(iOS 16.0, *) {
			modifier(OffersPresentationViewModifier(chargeOfferList: chargeOfferList))
		} else {
			self
		}
	}
}

// MARK: - Modifiers

@available(iOS 16.0, *)
private struct PresentationViewModifier: ViewModifier {
	@Binding var chargeOffer: ChargeOffer?

	func body(content: Content) -> some View {
		content
			.fullScreenCover(item: $chargeOffer) { chargeOffer in
				ChargeOfferResolutionFeature(chargeOffer: chargeOffer)
					.withEnvironmentObjects()
			}
	}
}

@available(iOS 16.0, *)
private struct OffersPresentationViewModifier: ViewModifier {
	@Binding var chargeOfferList: ChargeOfferList?

	func body(content: Content) -> some View {
		content
			.fullScreenCover(item: $chargeOfferList) { offerList in
				ChargeOfferDetailRootFeature(site: offerList.commonSite, offers: offerList.offers)
					.withEnvironmentObjects()
			}
	}
}
