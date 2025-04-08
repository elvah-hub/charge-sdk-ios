// Copyright © elvah. All rights reserved.

import Foundation

/// A configuration on how the primary action of a ``CampaignBanner`` view be resolved.
package enum CampaignBannerActionResolution {
	/// An automaic charge campaign action resolution.
	case automatic

	/// A custom-handled charge campaign action resolution.
	///
	/// You can use this to control the presentation of the campaign detail page or the charge
	/// presentation yourself.
	case custom(@MainActor (_ destination: CampaignBannerActionDestination) -> Void)
}
