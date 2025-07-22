// Copyright elvah. All rights reserved.

import Foundation

@_spi(Debug)
public extension ChargeSimulator.RequestHandlers {
  /// A charge flow that fails when attempting to stop the charge session.
  static var stopFails: Self {
    stopFails(siteProvider: .demo)
  }

  /// A charge flow that fails when attempting to stop the charge session.
  /// - Parameter siteProvider: The site provider to use for charge sites (live, demo, or custom).
  static func stopFails(siteProvider: SiteProvider) -> Self {
		Self(
      siteProvider: siteProvider,
      onStartRequest: {},
      onStopRequest: { _ in
        throw NetworkError.unexpectedServerResponse
      },
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
