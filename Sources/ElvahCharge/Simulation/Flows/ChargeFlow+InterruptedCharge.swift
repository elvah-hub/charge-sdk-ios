// Copyright © elvah. All rights reserved.

import Foundation

@_spi(Debug)
public extension ChargeSimulator.RequestHandlers {
  static var interruptedCharge: Self {
    interruptedCharge(siteProvider: .demo)
  }

  static func interruptedCharge(siteProvider: SiteProvider) -> Self {
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
          // Simulate unexpected interruption after 10 seconds of charging
          if context.elapsedSeconds > 10 && context.currentRequest != .stopRequested {
            return .stopped
          }
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