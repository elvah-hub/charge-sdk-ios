// Copyright © elvah. All rights reserved.

// Copyright elvah. All rights reserved
import Foundation

@_spi(Debug)
public extension ChargeSimulator.RequestHandlers {
  /// A charge flow that rejects the start request and remains in rejected state.
  static var startRejected: Self {
    startRejected(siteProvider: .demoSite)
  }

  /// A charge flow that rejects the start request and remains in rejected state.
  /// - Parameter siteProvider: The site provider to use for charge sites (live, demo, or custom).
  static func startRejected(siteProvider: SiteProvider) -> Self {
    Self(
      siteProvider: siteProvider,
      onStartRequest: {},
      onStopRequest: { _ in },
      onSessionPolling: { context in
        switch context.currentStatus {
        case .startRequested:
          if context.secondsSinceLastStatusChange > 6 {
            return .startRejected
          }
        case .startRejected:
          break
        case .started,
             .charging,
             .stopRequested,
             .stopRejected,
             .stopped:
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
