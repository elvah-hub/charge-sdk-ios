// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

@available(iOS 16.0, *)
extension ChargeProvider.SubscriptionManager {
  /// Waits until the number of subscribers is equal to the provided `count` or the `timeout` is
  /// reached.
  /// - Parameters:
  ///   - count: The expected subscriber count to wait for.
  ///   - timeout: The maximum duration to wait.
  /// - Throws: `SubscriberTimeoutError.timeout` if the expected subscriber count is not reached
  /// within the timeout.
  func waitForSubscriberCount(_ count: Int, timeout: Duration) async throws {
    if subscribers().count == count {
      return
    }

    let deadline = ContinuousClock.now.advanced(by: timeout)
    while subscribers().count != count {
      if ContinuousClock.now >= deadline {
        throw TimeoutError()
      }
      // Yield a short duration to allow other tasks (such as the async removal) to execute.
      try await Task.sleep(for: .milliseconds(50))
    }
  }
}
