// Copyright © elvah. All rights reserved.

import Defaults
import Foundation
import MapKit

public actor ChargeSimulator {
	package static let shared = ChargeSimulator()

	/// Internal storage of the simulated charge session data.
	private var _context: Context?

	private var configuration: Configuration = .init()
	private var requests: RequestHandlers = .default

	var signedOffers: [String: ChargeOffer] = [:]

	package init() {
		_context = Defaults[.simulationContext]
	}

	public static func configure(
		requestHandlers: RequestHandlers = .default,
		block: @Sendable @escaping (_ configuration: inout Configuration) -> Void = { _ in }
	) {
		Task {
			await shared.setRequestHandlers(requestHandlers)
			var configuration = await shared.configuration
			block(&configuration)
			await shared.setConfiguration(configuration)
		}
	}

	// MARK: - Configuration

	private func setConfiguration(_ configuration: Configuration) {
		self.configuration = configuration
	}

	private func setRequestHandlers(_ requests: RequestHandlers) {
		self.requests = requests
	}

	private func delay() async throws {
		try await Task.sleep(nanoseconds: configuration.responseDelay * NSEC_PER_MSEC)
	}

	// MARK: - Context Handling

	private func initializeContext(for chargeOffer: ChargeOffer) {
		let context = Context(
			configuration: configuration,
			chargeOffer: chargeOffer,
			session: ChargeSession(evseId: chargeOffer.evseId, status: .startRequested)
		)

		Defaults[.simulationContext] = context
	}

	private func context() throws -> Context {
		guard let simulation = Defaults[.simulationContext] else {
			throw NetworkError.unexpectedServerResponse
		}
		return simulation
	}

	@discardableResult private func updateContext(
		block: (_ context: inout Context) -> Void
	) throws -> Context {
		guard var simulation = Defaults[.simulationContext] else {
			throw NetworkError.unexpectedServerResponse
		}

		block(&simulation)
		Defaults[.simulationContext] = simulation
		return simulation
	}

	// MARK: - Services

	// MARK: Discovery Service

	package func siteOffers() async throws -> [ChargeSite] {
		try await delay()

		return try await requests.onSiteRequest()
	}

	package func signOffer() async throws -> SignedChargeOffer {
		try await delay()

		let signedOffer = SignedChargeOffer(
			offer: ChargeOffer.simulation,
			token: UUID().uuidString,
			validUntil: Date().addingTimeInterval(60 * 5)
		)

		signedOffers[signedOffer.token] = signedOffer.offer
		return signedOffer
	}

	// MARK: Charge Settlement Service

	package func stripeConfiguration() async throws -> StripeConfiguration {
		try await delay()
		return configuration.stripeConfiguration
	}

	package func initiate(signedOffer: String) async throws -> PaymentContext {
		try await delay()

		var paymentContext = configuration.paymentContext

		// Set the payment id to be the signed offer for easy retrieval
		paymentContext.paymentId = signedOffer

		return paymentContext
	}

	package func authorize(paymentId: String) async throws -> ChargeAuthentication {
		try await delay()

		var chargeAuthentication = configuration.chargeAuthentication

		// Set the token to be the payment id (which is the signed offer) for easy retrieval
		chargeAuthentication.token = paymentId

		return chargeAuthentication
	}

	// MARK: Charge Service

	func start(authentication: ChargeAuthentication) async throws {
		try await delay()

		guard let chargeOffer = signedOffers[authentication.token] else {
			throw NetworkError.unexpectedServerResponse
		}

		try await requests.onStartRequest()
		initializeContext(for: chargeOffer)

		try updateContext { context in
			context.currentRequest = .startRequested
		}
	}

	func stop(authentication: ChargeAuthentication) async throws {
		try await delay()
		let context = try context()

		try await requests.onStopRequest(context)

		try updateContext { context in
			context.currentRequest = .stopRequested
		}
	}

	func session(
		authentication: ChargeAuthentication
	) async throws -> ChargeSession {
		try await delay()

		var context = try updateContext { context in
			context.progressSession()
			context.elapsedSeconds = Date().timeIntervalSince(context.startedAt)
			context.secondsSinceLastPolling = Date().timeIntervalSince(context.lastPolledAt)
		}

		let newStatus = try await requests.onSessionPolling(context)
		context = try updateContext { context in
			if let newStatus {
				context.session.status = newStatus
			}
			context.lastPolledAt = Date()

			// Reset request
			context.currentRequest = nil
		}

		return context.session
	}

	package func summary(paymentId: String) async throws -> PaymentSummary {
		try await delay()
		return try context().generateSummary()
	}
}

public extension ChargeSimulator {
	struct Context: Codable, Sendable, Defaults.Serializable {
		var configuration: Configuration
		var chargeOffer: ChargeOffer
		var session: ChargeSession

		public package(set) var currentStatus: ChargeSession.Status? {
			get { session.status }
			set { session.status = newValue }
		}

		public package(set) var currentRequest: Request? = .startRequested
		public package(set) var startedAt: Date = .init()
		public package(set) var stoppedAt: Date?
		public package(set) var elapsedSeconds: TimeInterval = 0
		public package(set) var lastPolledAt: Date = .distantPast
		public package(set) var secondsSinceLastPolling: TimeInterval = 0

		public var hasRequest: Bool {
			currentRequest != nil
		}

		public var hasStopped: Bool {
			currentStatus == .stopped
		}

		package mutating func progressSession() {
			session.duration = Date().timeIntervalSince(startedAt)

			switch session.status {
			case .startRequested:
				break
			case .started:
				break
			case .charging:
				let power = chargeOffer.chargePoint.maxPowerInKw
				session.consumption = KilowattHours(power * Double(session.duration) / 3600)
			case .stopRequested:
				break
			case .stopped:
				stoppedAt = Date()
			default:
				break
			}
		}

		package func generateSummary() throws -> PaymentSummary {
			return PaymentSummary(
				consumedKWh: session.consumption,
				sessionStartedAt: startedAt,
				sessionEndedAt: stoppedAt ?? Date(),
				totalCost: chargeOffer.price.pricePerKWh * session.consumption.value
			)
		}

		public enum Request: Codable, Sendable {
			case startRequested
			case stopRequested
		}
	}

	struct Configuration: Sendable, Codable, Defaults.Serializable {
		/// The simulated delay in milliseconds that is added before answering charge session requests.
		///
		/// Defaults to 300ms.
		public var responseDelay: UInt64 = 300

		package var stripeConfiguration = StripeConfiguration.simulation
		package var chargeAuthentication = ChargeAuthentication.simulation
		package var paymentContext = PaymentContext.simulation
	}
}

// MARK: - Defaults

private extension Defaults.Keys {
	static let simulationContext = Key<ChargeSimulator.Context?>(
		Elvah.id.uuidString + "-chargeSimulation",
		default: nil
	)
}

// MARK: - Request Handlers

public extension ChargeSimulator {
	struct RequestHandlers: Sendable {
		public typealias SiteRequest = @Sendable () async throws -> [ChargeSite]
		public typealias StartRequest = @Sendable () async throws -> Void
		public typealias StopRequest = @Sendable (_ session: Context) async throws -> Void
		public typealias SessionRequest = @Sendable (
			_ session: Context
		) async throws -> ChargeSession.Status?

		public package(set) var onSiteRequest: SiteRequest
		public package(set) var onStartRequest: StartRequest
		public package(set) var onStopRequest: StopRequest
		public package(set) var onSessionPolling: SessionRequest

		public init(
			onSiteRequest: @escaping SiteRequest,
			onStartRequest: @escaping StartRequest,
			onStopRequest: @escaping StopRequest,
			onSessionPolling: @escaping SessionRequest
		) {
			self.onSiteRequest = onSiteRequest
			self.onStartRequest = onStartRequest
			self.onStopRequest = onStopRequest
			self.onSessionPolling = onSessionPolling
		}

		public static var `default`: RequestHandlers {
			RequestHandlers(
				onSiteRequest: {
					[ChargeSite(site: .simulation, offers: [.simulation])]
				},
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
}
