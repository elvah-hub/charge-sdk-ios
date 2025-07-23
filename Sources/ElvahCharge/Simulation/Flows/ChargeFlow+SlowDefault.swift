// Copyright elvah. All rights reserved.

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
					if context.secondsSinceLasStatusChange > 8 {
            return .started
          }
        case .startRejected:
          break
        case .started:
          if context.secondsSinceLasStatusChange > 6 {
            return .charging
          }
        case .charging:
          if context.currentRequest == .stopRequested {
            return .stopRequested
          }
        case .stopRequested:
          if context.secondsSinceLasStatusChange > 7 {
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
      }
    )
  }
}
