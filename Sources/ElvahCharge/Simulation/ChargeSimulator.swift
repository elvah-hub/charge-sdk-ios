// Copyright © elvah. All rights reserved.

import Defaults
import Foundation
import MapKit

@_spi(Debug)
public actor ChargeSimulator {
	package static let shared = ChargeSimulator()

	/// Internal storage of the simulated charge session data.
	private var _context: Context?

	private var configuration: Configuration = .init()
	private var requests: RequestHandlers = .init(
		siteProvider: .demoSite,
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

	var signedOffers: [String: ChargeOffer] = [:]

	package init() {
		_context = Defaults[.simulationContext]
	}

	public static func configure(
		flow requestHandlers: RequestHandlers = RequestHandlers(
			siteProvider: .demoSite,
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
		),
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

	package func sites(
		region: MKMapRect?,
		evseIds: [String]?,
		onlyCampaigns: Bool
	) async throws -> [ChargeSite] {
		precondition(region != nil || evseIds != nil, "Either region or evseIds must be provided")
		try await delay()

		if let region {
			return try await requests.siteProvider.sites(in: region, onlyCampaigns: onlyCampaigns)
		} else if let evseIds {
			return try await requests.siteProvider.sites(
				forEvseIds: evseIds,
				onlyCampaigns: onlyCampaigns
			)
		}

		throw NetworkError.unexpectedServerResponse
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
			// Update the context data
			context.progressSession()
			context.elapsedSeconds = Date().timeIntervalSince(context.startedAt)
			context.secondsSinceLastPolling = Date().timeIntervalSince(context.lastPolledAt)
			context.secondsSinceLasStatusChange = Date().timeIntervalSince(context.statusLastChangedAt)
		}

		let newStatus = try await requests.onSessionPolling(context)
		context = try updateContext { context in
			// Update session status if needed
			if let newStatus {
				context.session.status = newStatus
				context.statusLastChangedAt = Date()
			}

			// Update context data
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

@_spi(Debug)
public extension ChargeSimulator {
	/// Context information about a current simulated charge session.
	struct Context: Codable, Sendable, Defaults.Serializable {
		var configuration: Configuration
		var chargeOffer: ChargeOffer
		var session: ChargeSession

		/// Current status of the charge session.
		public package(set) var currentStatus: ChargeSession.Status? {
			get { session.status }
			set { session.status = newValue }
		}

		/// Current request being processed in the session.
		///
		/// You should use this to respond to a user interaction, like them trying to start or stop the
		/// session.
		public package(set) var currentRequest: Request? = .startRequested

		/// Date at which the session started.
		public package(set) var startedAt: Date = .init()

		/// Date at which the session stopped.
		///
		/// This will be `nil` if the session has not stopped yet.
		public package(set) var stoppedAt: Date?

		/// Seconds elapsed since the session started.
		public package(set) var elapsedSeconds: TimeInterval = 0

		/// Last time the session was polled.
		public package(set) var lastPolledAt: Date = .distantPast

		/// Seconds since the last polling.
		public package(set) var secondsSinceLastPolling: TimeInterval = 0

		/// Date at which the session's status last has changed.
		public package(set) var statusLastChangedAt: Date = .distantPast

		/// Seconds since the last time the session's status has changed.
		public package(set) var secondsSinceLasStatusChange: TimeInterval = 0

		/// Returns `true` if a request is ongoing.
		public var hasRequest: Bool {
			currentRequest != nil
		}

		/// Returns `true` if the session has stopped.
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

		/// A user request.
		public enum Request: Codable, Sendable {
			/// A request to start the charge session.
			case startRequested

			/// A request to stop the charge session.
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

@_spi(Debug)
public extension ChargeSimulator {
	struct RequestHandlers: Sendable {
		public typealias StartRequest = @Sendable () async throws -> Void
		public typealias StopRequest = @Sendable (_ session: Context) async throws -> Void
		public typealias SessionRequest = @Sendable (
			_ session: Context
		) async throws -> ChargeSession.Status?

		public package(set) var siteProvider: SiteProvider
		public package(set) var onStartRequest: StartRequest
		public package(set) var onStopRequest: StopRequest
		public package(set) var onSessionPolling: SessionRequest

		public init(
			siteProvider: SiteProvider,
			onStartRequest: @escaping StartRequest,
			onStopRequest: @escaping StopRequest,
			onSessionPolling: @escaping SessionRequest
		) {
			self.siteProvider = siteProvider
			self.onStartRequest = onStartRequest
			self.onStopRequest = onStopRequest
			self.onSessionPolling = onSessionPolling
		}

		public enum SiteProvider: Sendable {
			/// A site provider that calls the live API to fetch charge sites.
			///
			/// - Important: A valid api key is needed for live site requests to work. You can configure
			/// the simulation mode with an api key by passing it to
			/// ``Elvah/Configuration/simulation(apiKey:theme:store:)``.
			case live

			/// A site provider that accepts a closure that returns the charge sites.
			///
			/// You can use this to pass your own charge sites for the simulation to use.
			case custom(
				@Sendable (
					_ region: MKMapRect?,
					_ evseIds: [String]?,
					_ onlyCampaigns: Bool
				) async throws -> [ChargeSite]
			)

			public static var demoSite: Self {
				.custom { _, _, _ in
					[ChargeSite(site: .simulation, offers: [.simulation])]
				}
			}

			package func sites(
				forEvseIds evseIds: [String],
				onlyCampaigns: Bool
			) async throws -> [ChargeSite] {
				switch self {
				case .live:
					if Elvah.configuration.apiKey != "" {
						Elvah.logger.warning(
							"""
							You are using a live site provider but no API key was configured. \
							This will prevent any live site requests from working.
							"""
						)
					}

					if onlyCampaigns {
						return try await DiscoveryProvider.live.campaigns(forEvseIds: evseIds)
					}
					return try await DiscoveryProvider.live.sites(forEvseIds: evseIds)
				case let .custom(closure):
					return try await closure(nil, evseIds, onlyCampaigns)
				}
			}

			package func sites(
				in region: MKMapRect,
				onlyCampaigns: Bool
			) async throws -> [ChargeSite] {
				switch self {
				case .live:
					if Elvah.configuration.apiKey != "" {
						Elvah.logger.warning(
							"""
							You are using a live site provider but no API key was configured. \
							This will prevent any live site requests from working.
							"""
						)
					}

					if onlyCampaigns {
						return try await DiscoveryProvider.live.campaigns(in: region)
					}
					return try await DiscoveryProvider.live.sites(in: region)
				case let .custom(closure):
					return try await closure(region, nil, onlyCampaigns)
				}
			}
		}
	}
}
