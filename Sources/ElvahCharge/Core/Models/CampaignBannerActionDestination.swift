// Copyright © elvah. All rights reserved.

import Foundation

/// The requested destination by the primary action of a ``CampaignBanner`` view.
public enum CampaignBannerActionDestination {
	/// The campaign detail page destination.
	///
	/// You can pass the given ``Campaign`` object to a `.chargeCampaign(providing:)` view modifier to
	/// present the campaign detail page in your view hierarchy.
	case campaignDetailPresentation(Campaign)

	/// The charge session destination.
	///
	/// You can use the `.chargeSessionPresentation(isPresented:)` view
	/// modifier to present the currently active charge session.
	case chargeSessionPresentation
}
