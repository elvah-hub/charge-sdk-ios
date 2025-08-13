// Copyright © elvah. All rights reserved.

import Foundation

/// The requested destination by the primary action of a ``ChargeBanner`` view.
public enum ChargeBannerActionDestination {
	/// The charge site detail page destination.
	///
	/// You can pass the given ``ChargeSite`` object to a `.chargePresentation(site:)` view modifier to
	/// present the charge site detail page in your view hierarchy.
	case chargeSitePresentation(ChargeSite)

	/// The charge session destination.
	///
	/// You can use the `.chargeSessionPresentation(isPresented:)` view
	/// modifier to present the currently active charge session.
	case chargeSessionPresentation
}
