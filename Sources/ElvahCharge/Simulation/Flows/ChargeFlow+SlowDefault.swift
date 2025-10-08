// Copyright © elvah. All rights reserved.

import Foundation

@_spi(Debug)
public extension ChargeSimulator.RequestHandlers {
  /// A default charge flow with slower timing for testing delayed responses.
  static var slowDefault: Self {
    slowDefault(siteProvider: .demoSite)
  }

  /// A default charge flow with slower timing for testing delayed responses.
  /// - Parameter siteProvider: The site provider to use for charge sites (live, demo, or custom).
  static func slowDefault(siteProvider: SiteProvider) -> Self {
    Self(
      siteProvider: siteProvider,
      onStartRequest: {},
      onStopRequest: { _ in },
      onSessionPolling: { context in
        switch context.currentStatus {
        case .startRequested:
          if context.secondsSinceLastStatusChange > 8 {
            return .started
          }
        case .startRejected:
          break
        case .started:
          if context.secondsSinceLastStatusChange > 6 {
            return .charging
          }
        case .charging:
          if context.currentRequest == .stopRequested {
            return .stopRequested
          }
        case .stopRequested:
          if context.secondsSinceLastStatusChange > 7 {
            return .stopped
          }
        case .stopRejected:
          break
        case .stopped:
          break
        case nil:
          if context.currentRequest == .startRequested {
            return .startRequested
          }
        }

        return nil
      },
    )
  }
}
