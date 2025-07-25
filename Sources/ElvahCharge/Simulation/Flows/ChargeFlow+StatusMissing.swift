// Copyright © elvah. All rights reserved.

import Foundation

@_spi(Debug)
public extension ChargeSimulator.RequestHandlers {
	/// A charge flow that fails when attempting to start the charge session.
	static var statusMissing: Self {
		statusMissing(siteProvider: .demoSite)
	}

	/// A charge flow that fails to set the session status.
	/// - Parameter siteProvider: The site provider to use for charge sites (live, demo, or custom).
	static func statusMissing(siteProvider: SiteProvider) -> Self {
		Self(
			siteProvider: siteProvider,
			onStartRequest: {},
			onStopRequest: { _ in },
			onSessionPolling: { _ in nil }
		)
	}
}
