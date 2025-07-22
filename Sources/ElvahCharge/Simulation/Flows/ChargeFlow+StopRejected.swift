// Copyright elvah. All rights reserved.

import Foundation

@_spi(Debug)
public extension ChargeSimulator.RequestHandlers {
  /// A charge flow that rejects stop requests and continues charging.
  static var stopRejected: Self {
    stopRejected(siteProvider: .demo)
  }

  /// A charge flow that rejects stop requests and continues charging.
  /// - Parameter siteProvider: The site provider to use for charge sites (live, demo, or custom).
  static func stopRejected(siteProvider: SiteProvider) -> Self {
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
          if context.elapsedSeconds > 4 {
            return .stopRejected
          }
        case .stopRejected:
          // After stop rejection, continue charging
          if context.elapsedSeconds > 8 {
            return .charging
          }
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