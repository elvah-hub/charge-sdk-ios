// Copyright elvah. All rights reserved.

import Foundation

@_spi(Debug)
public extension ChargeSimulator.RequestHandlers {
  /// A standard charge flow that completes successfully with typical timing.
  static var `default`: Self {
    `default`(siteProvider: .demoSite)
  }

  /// A standard charge flow that completes successfully with typical timing.
  /// - Parameter siteProvider: The site provider to use for charge sites (live, demo, or custom).
  static func `default`(siteProvider: SiteProvider) -> Self {
		Self(
      siteProvider: siteProvider,
      onStartRequest: {},
      onStopRequest: { _ in },
      onSessionPolling: { context in
        switch context.currentStatus {
        case .startRequested:
          if context.secondsSinceLastStatusChange > 3 {
            return .started
          }
        case .startRejected:
          break
        case .started:
          if context.secondsSinceLastStatusChange > 2 {
            return .charging
          }
        case .charging:
          if context.currentRequest == .stopRequested {
            return .stopRequested
          }
        case .stopRequested:
          if context.secondsSinceLastStatusChange > 3 {
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
