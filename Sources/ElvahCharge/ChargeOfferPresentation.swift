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
	/// - Parameters:
	///   - chargeOffer: The charge offer that should be resolved. This must be part of the provided
	/// charge site.
	/// - Returns: A view that presents a modal that handles payment and charging for a specific
	/// charge point.
	@ViewBuilder func chargePresentation(chargeOffer: Binding<ChargeOffer?>) -> some View {
		if #available(iOS 16.0, *) {
			modifier(PresentationViewModifier(chargeOffer: chargeOffer))
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
