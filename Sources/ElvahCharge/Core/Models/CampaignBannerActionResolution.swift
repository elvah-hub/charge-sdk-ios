// Copyright © elvah. All rights reserved.

import Foundation

/// A configuration on how the primary action of a ``ChargeBanner`` view be resolved.
package enum ChargeBannerActionResolution {
	/// An automatic charge offer action resolution.
	case automatic

	/// A custom-handled charge offer action resolution.
	///
	/// You can use this to control the presentation of the charge
	/// presentation yourself.
	case custom(@MainActor (_ destination: ChargeBannerActionDestination) -> Void)
}
