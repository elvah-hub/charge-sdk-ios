// Copyright © elvah. All rights reserved.

import Foundation

@_spi(Debug)
public extension ChargeSimulator.RequestHandlers {
  static var startRejected: Self {
    startRejected(siteProvider: .demo)
  }

  static func startRejected(siteProvider: SiteProvider) -> Self {
    Self(
      siteProvider: siteProvider,
      onStartRequest: {},
      onStopRequest: { _ in },
      onSessionPolling: { context in
        switch context.currentStatus {
        case .startRequested:
          if context.elapsedSeconds > 2 {
            return .startRejected
          }
        case .startRejected:
          break
        case .started, .charging, .stopRequested, .stopRejected, .stopped:
          break
        case nil:
          if context.currentRequest == .startRequested {
            return .startRequested
          }
        }

        return nil
      }
    )
  }
}