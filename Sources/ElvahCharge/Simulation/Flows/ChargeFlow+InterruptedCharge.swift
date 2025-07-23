// Copyright elvah. All rights reserved.

import Foundation

@_spi(Debug)
public extension ChargeSimulator.RequestHandlers {
  /// A charge flow that gets unexpectedly interrupted during the charging phase.
  static var interruptedCharge: Self {
    interruptedCharge(siteProvider: .demoSite)
  }

  /// A charge flow that gets unexpectedly interrupted during the charging phase.
  /// - Parameter siteProvider: The site provider to use for charge sites (live, demo, or custom).
  static func interruptedCharge(siteProvider: SiteProvider) -> Self {
    Self(
      siteProvider: siteProvider,
      onStartRequest: {},
      onStopRequest: { _ in },
      onSessionPolling: { context in
        switch context.currentStatus {
        case .startRequested:
          if context.secondsSinceLasStatusChange > 3 {
            return .started
          }
        case .startRejected:
          break
        case .started:
          if context.secondsSinceLasStatusChange > 2 {
            return .charging
          }
        case .charging:
          // Simulate unexpected interruption after 8 seconds of charging
          if context.secondsSinceLasStatusChange > 8
							&& context.currentRequest != .stopRequested {
            return .stopped
          }
          if context.currentRequest == .stopRequested {
            return .stopRequested
          }
        case .stopRequested:
          if context.secondsSinceLasStatusChange > 3 {
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
