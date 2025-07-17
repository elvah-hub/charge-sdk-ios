// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *) @MainActor
final class ChargeSettlementProvider: ObservableObject {
	struct Dependencies: Sendable {
		var stripeConfiguration: @Sendable () async throws -> StripeConfiguration
		var initiate: @Sendable (_ signedOffer: String) async throws -> PaymentContext
		var authorize: @Sendable (_ paymentId: String) async throws -> ChargeAuthentication
		var summary: @Sendable (_ paymentId: String) async throws -> PaymentSummary?
	}

	private let dependencies: Dependencies

	nonisolated init(dependencies: Dependencies) {
		self.dependencies = dependencies
	}

	func initiate(with signedOffer: String) async throws -> PaymentContext {
		try await dependencies.initiate(signedOffer)
	}

	func authorize(paymentId: String) async throws
		-> ChargeAuthentication {
		try await dependencies.authorize(paymentId)
	}

	func stripeConfiguration() async throws -> StripeConfiguration {
		try await dependencies.stripeConfiguration()
	}

	func summary(paymentId: String) async throws -> PaymentSummary? {
		try await dependencies.summary(paymentId)
	}
}

@available(iOS 16.0, *)
extension ChargeSettlementProvider {
	static let live = {
		let service = ChargeSettlementService(
			apiKey: Elvah.configuration.apiKey,
			environment: Elvah.configuration.environment
		)
		return ChargeSettlementProvider(
			dependencies: .init(
				stripeConfiguration: {
					try await service.stripeConfiguration()
				},
				initiate: { signedOffer in
					try await service.initiate(signedOffer: signedOffer)
				},
				authorize: { paymentId in
					try await service.authorizeSession(paymentId: paymentId)
				},
				summary: { paymentId in
					try await service.summary(paymentId: paymentId)
				}
			)
		)
	}()

	static let simulation = ChargeSettlementProvider(
		dependencies: .init(
			stripeConfiguration: {
				try await Simulator.shared.stripeConfiguration()
			},
			initiate: { signedOffer in
				try await Simulator.shared.initiate(signedOffer: signedOffer)
			},
			authorize: { paymentIntentId in
				try await Simulator.shared.authorize(paymentIntentId: paymentIntentId)
			},
			summary: { paymentId in
				try await Simulator.shared.summary(paymentId: paymentId)
			}
		)
	)

	static let mock = ChargeSettlementProvider(
		dependencies: .init(
			stripeConfiguration: {
				try await Task.sleep(for: .milliseconds(200))
				return StripeConfiguration(publishableKey: "mock publishable key")
			},
			initiate: { signedOffer in
				try await Task.sleep(for: .milliseconds(200))
				return PaymentContext(
					clientSecret: "",
					paymentId: "",
					paymentIntentId: "",
					accountId: "",
					authorizationAmount: 0.42,
					organisationDetails: .mock
				)
			},
			authorize: { paymentIntentId in
				try await Task.sleep(for: .milliseconds(200))
				return ChargeAuthentication(token: "", expiryDate: nil)
			},
			summary: { paymentId in
				try await Task.sleep(for: .milliseconds(200))
				return PaymentSummary.mock
			}
		)
	)
}
