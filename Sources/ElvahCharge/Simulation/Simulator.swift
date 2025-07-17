// Copyright © elvah. All rights reserved.

import Defaults
import Foundation
import MapKit

actor Simulator {
	static let shared = Simulator()

	private var configuration = Configuration()

	private init() {}

	// MARK: - Simulation

	private func simulation() throws -> ChargeSimulation {
		guard let simulation = Defaults[.simulation] else {
			throw NetworkError.unexpectedServerResponse
		}
		return simulation
	}

	@discardableResult private func updateSimulation(
		initialize: Bool = false,
		block: (_ simulation: inout ChargeSimulation) -> Void
	) throws -> ChargeSimulation {
		if initialize {
			Defaults[.simulation] = ChargeSimulation(configuration: configuration)
		}

		guard var simulation = Defaults[.simulation] else {
			throw NetworkError.unexpectedServerResponse
		}

		block(&simulation)
		Defaults[.simulation] = simulation
		return simulation
	}

	private func wait(milliseconds: UInt64) async throws {
		try await Task.sleep(nanoseconds: milliseconds * NSEC_PER_MSEC)
	}

	// MARK: - Configuration

	func configure(_ block: (_ confiuguration: inout Simulator.Configuration) -> Void) async throws {
		var configuration = configuration
		block(&configuration)
		self.configuration = configuration
	}

	// MARK: - Discovery Service

	func siteOffers() async throws -> [ChargeSite] {
		[ChargeSite(site: .simulation, offers: [ChargeOffer.simulation])]
	}

	func signOffer() async throws -> SignedChargeOffer {
		SignedChargeOffer(offer: ChargeOffer.simulation, signedOffer: "")
	}

	// MARK: Charge Settlement Service

	func stripeConfiguration() async throws -> StripeConfiguration {
		try await wait(milliseconds: 300)
		return configuration.stripeConfiguration
	}

	func initiate(signedOffer: String) async throws -> PaymentContext {
		try await wait(milliseconds: 300)
		return configuration.paymentContext
	}

	func authorize(paymentIntentId: String) async throws -> ChargeAuthentication {
		try await wait(milliseconds: 300)
		return configuration.chargeAuthentication
	}

	func summary(paymentId: String) async throws -> PaymentSummary {
		try await wait(milliseconds: 300)
		return try simulation().summary()
	}

	// MARK: Charge Service

	func start(authentication: ChargeAuthentication) async throws {
		try await wait(milliseconds: 300)
		Defaults[.simulation] = ChargeSimulation(configuration: configuration)
		try updateSimulation(initialize: true) { simulation in
			simulation.requestStart()
		}
	}

	func session(
		authentication: ChargeAuthentication
	) async throws -> ChargeSession {
		try await wait(milliseconds: 300)
		return try updateSimulation { simulation in
			simulation.progress()
		}.session
	}

	func stop(authentication: ChargeAuthentication) async throws {
		try await wait(milliseconds: 300)
		try updateSimulation { simulation in
			simulation.requestStop()
		}
	}
}

extension Simulator {
	struct ChargeSimulation: Codable, Hashable, Sendable, Defaults.Serializable {
		var configuration: Simulator.Configuration

		var startedAt: Date = .init()
		var stoppedAt: Date?
		var session: ChargeSession

		init(configuration: Simulator.Configuration) {
			self.configuration = configuration
			session = ChargeSession(
				evseId: "",
				status: .startRequested,
				consumption: 0,
				duration: 0,
			)
		}

		mutating func progress() {
			let elapsedSeconds = Date().timeIntervalSince(startedAt)
			session.duration = Date().timeIntervalSince(startedAt)

			switch session.status {
			case .startRequested:
				if elapsedSeconds > 3 {
					session.status = .started
				}
			case .started:
				if elapsedSeconds > 3 {
					session.status = .charging
				}
			case .charging:
				session.consumption = KilowattHours(Double(session.duration) * 0.9)
			case .stopRequested:
				if elapsedSeconds > 3 {
					session.status = .stopped
					stoppedAt = Date()
				}
			case .stopped:
				break
			default:
				break
			}
		}

		mutating func requestStart() {
			session.evseId = "mock evse id"
			session.status = .startRequested
			progress()
		}

		mutating func requestStop() {
			session.status = .stopRequested
			progress()
		}

		mutating func cancelRequestedStop() {
			session.status = .stopped
			progress()
		}

		func summary() -> PaymentSummary {
			PaymentSummary(
				consumedKWh: session.consumption,
				sessionStartedAt: startedAt,
				sessionEndedAt: stoppedAt ?? Date(),
				totalCost: ChargeOffer.simulation.price.pricePerKWh * session.consumption.value
			)
		}
	}

	struct Configuration: Sendable, Hashable, Codable, Defaults.Serializable {
		// TODO: Add new charge offer type to configuration
		var stripeConfiguration = StripeConfiguration.simulation
		var chargeAuthentication = ChargeAuthentication.simulation
		var paymentContext = PaymentContext.simulation
	}
}

// MARK: - Defaults

private extension Defaults.Keys {
	static let simulation = Key<Simulator.ChargeSimulation?>(
		Elvah.id.uuidString + "-chargeSimulation",
		default: nil
	)
}
