// Copyright elvah. All rights reserved.

import Foundation

@_spi(Debug)
public extension ChargeSimulator.RequestHandlers {
  /// A standard charge flow that completes successfully with typical timing.
  static var `default`: Self {
    `default`(siteProvider: .demo)
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
          if context.elapsedSeconds > 3 {
            return .started
          }
        case .startRejected:
          break
        case .started:
          if context.elapsedSeconds > 5 {
            return .charging
          }
        case .charging:
          if context.currentRequest == .stopRequested {
            return .stopRequested
          }
        case .stopRequested:
          if context.elapsedSeconds > 7 {
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
