// Copyright © elvah. All rights reserved.

// Copyright elvah. All rights reserved.
import Foundation

@_spi(Debug)
public extension ChargeSimulator.RequestHandlers {
  /// A charge flow that fails when attempting to start the charge session.
  static var startFails: Self {
    startFails(siteProvider: .demoSite)
  }

  /// A charge flow that fails when attempting to start the charge session.
  /// - Parameter siteProvider: The site provider to use for charge sites (live, demo, or custom).
  static func startFails(siteProvider: SiteProvider) -> Self {
    Self(
      siteProvider: siteProvider,
      onStartRequest: {
        throw NetworkError.unexpectedServerResponse
      },
      onStopRequest: { _ in },
      onSessionPolling: { _ in
        nil
      },
    )
  }
}
