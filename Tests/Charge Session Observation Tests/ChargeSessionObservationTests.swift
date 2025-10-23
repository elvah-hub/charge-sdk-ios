// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

#if canImport(Defaults)
  import Defaults
#endif

@Suite("Charge Session Observation Tests")
@MainActor
struct ChargeSessionObservationTests {
  @available(iOS 16.0, *) typealias Stream = ChargeProvider.SessionUpdateStream

  @available(iOS 16.0, *) init() {
    Defaults[.mockChargeSessionContext] = nil
  }

  @Test("Basic charge session observation with state transitions") @available(iOS 16.0, *) func basicObservation() async throws {
    let subscriptionManager = ChargeProvider.SubscriptionManager()

    let mockSessionContext = ChargeSessionContext(
      site: .mock,
      signedOffer: .mockAvailable,
      organisationDetails: PaymentContext
        .OrganisationDetails(
          companyName: "company",
          logoUrl: nil,
          privacyUrl: nil,
          termsOfConditionUrl: nil,
          supportMethods: [],
        ),
      authentication: .mock,
      paymentId: "mock",
      startedAt: Date(),
    )

    let simulator = ChargeSessionSimulator(
      session: ChargeSession(
        evseId: "evseId",
        status: .charging,
        consumption: 42,
        duration: 0,
      ),
    )

    let chargeProvider = ChargeProvider(
      dependencies: ChargeProvider.Dependencies(
        subscriptionManager: subscriptionManager,
        session: { _ in
          try await simulator.fetchSession()
        },
        start: { _ in },
        stop: { _ in },
      ),
    )

    // Create a new update stream
    let stream = ChargeSession.observation.updates(
      using: chargeProvider,
      sessionContextKey: .mockChargeSessionContext,
    )

    // Grab the stream's iterator
    var iterator = stream.makeAsyncIterator()

    // Make sure the stream initially yields .inactive
    try await #expect(iterator.next() == .inactive)

    // Write a mock session context to storage
    Defaults[.mockChargeSessionContext] = mockSessionContext

    // Make sure the stream recognized that and yields .active without session data
    try await #expect(iterator.next() == .active(nil))

    // Finally, make sure the stream yields .active WITH session data
    let sessionData = try await #require(iterator.next()?.sessionData)
    #expect(sessionData.consumption.value == 42.0)
  }
}

// MARK: - Helpers

@available(iOS 16.0, *)
extension Defaults.Keys {
  static let mockChargeSessionContext = Key<ChargeSessionContext?>(
    Elvah.id.uuidString + "-chargeSessionContext",
    default: nil,
    suite: UserDefaults(suiteName: "0299810F-6B6D-44F8-AB80-22388BC6FE73")!,
  )
}
