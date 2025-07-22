// Copyright © elvah. All rights reserved.

import Foundation

@_spi(Debug)
public extension ChargeSimulator.RequestHandlers {
  static var startFails: Self {
    startFails(siteProvider: .demo)
  }

  static func startFails(siteProvider: SiteProvider) -> Self {
		Self(
      siteProvider: siteProvider,
      onStartRequest: {
        throw NetworkError.unexpectedServerResponse
      },
      onStopRequest: { _ in },
      onSessionPolling: { _ in
        nil
      }
    )
  }
}
