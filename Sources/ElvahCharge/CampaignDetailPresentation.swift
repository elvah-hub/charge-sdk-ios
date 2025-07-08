// Copyright © elvah. All rights reserved.

import SwiftUI

public extension View {
	/// Presents a modal view showing a campaign detail view where users can start a new in-app charge
	/// session. Its presentation is controlled by the provided binding to a ``Campaign`` object.
	///
	/// You can fetch a ``Campaign`` object by calling ``Campaign/campaigns(in:)`` or
	/// one of its adjacent methods.
	/// - Important: This modifier requires iOS 16.0 or later. On earlier versions, it does nothing to
	/// the wrapped view.
	/// - Returns: A view that presents a campaign detail view using the given ``Campaign`` object.
	@ViewBuilder func campaignDetailPresentation(
		for campaign: Binding<Campaign?>
	) -> some View {
		if #available(iOS 16.0, *) {
			modifier(PresentationViewModifier(campaign: campaign))
		} else {
			self
		}
	}
}

// MARK: - Modifiers

@available(iOS 16.0, *)
private struct PresentationViewModifier: ViewModifier {
	@Binding var campaign: Campaign?

	func body(content: Content) -> some View {
		content
			.fullScreenCover(item: $campaign) { campaign in
				ChargeOfferDetailRootFeature(
					site: campaign.chargeSite.site,
					offers: campaign.chargeSite.offers
				)
			}
	}
}
