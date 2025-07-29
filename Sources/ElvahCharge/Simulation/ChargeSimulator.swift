// Copyright © elvah. All rights reserved.

import Defaults
import Foundation
import MapKit

/// A simulation engine for testing EV charge session flows without requiring real hardware or
/// network connections.
///
/// `ChargeSimulator` provides a complete simulation environment for charge sessions by intercepting
/// network requests
/// and replacing them with configurable behaviors. This allows developers to test various charge
/// scenarios including successful flows, failures, and edge cases.
///
/// - Note: The simulator is only available in debug builds via the `@_spi(Debug)` attribute.
/// - Warning: The `ChargeSimulator` is not part of the public api contract. Do not rely on it in production code.
///
/// ## Core Concepts
///
/// ### Request Handler Flows
/// The simulator's behavior is defined by **request handler flows** - sets of closures that
/// intercept and respond to
/// different types of network requests. Each flow defines:
///
/// - **Site Provider**: How charge sites are discovered (live API, demo data, or custom)
/// - **Start Handler**: Behavior when a charge session start is requested
/// - **Stop Handler**: Behavior when a charge session stop is requested
/// - **Session Polling Handler**: How the session status evolves over time during polling
///
/// ### Built-in Flows
/// The simulator includes several pre-built flows in the `Flows/` directory:
///
/// - `.default` - Standard successful charge flow with typical timing
/// - `.startFails` - Simulates start request failures
/// - `.startRejected` - Start request is rejected by the charge point
/// - `.stopFails` - Simulates stop request failures
/// - `.stopRejected` - Stop request is rejected by the charge point
/// - `.interruptedCharge` - Charge session gets unexpectedly interrupted
/// - `.slowDefault` - Similar to default but with slower transitions
/// - `.statusMissing` - Session status is never set
///
/// ## Basic Usage
///
/// To use the charge simulator, simply initialize the SDK in simulation mode:
///
/// ```swift
/// // Enable simulation mode – no additional setup required
/// Elvah.initialize(with: .simulator)
/// ```
///
/// By default, the simulator uses a standard successful flow. No further configuration is necessary
/// for most testing scenarios.
///
/// If you want to simulate specific behaviors or customize the flow, call
/// `ChargeSimulator.configure`.
/// Note that this requires importing `ElvahCharge` with `@_spi(Debug)` access:
///
/// ```swift
/// // Import debug API for advanced simulator flows
/// @_spi(Debug) import ElvahCharge
///
/// // Use a specific flow
/// ChargeSimulator.configure(flow: .startFails)
///
/// // Or customize configuration
/// ChargeSimulator.configure(flow: .default) { config in
///   config.responseDelay = 500 // 500ms delay
/// }
/// ```
///
/// ## Creating Custom Flows
///
/// You can create custom request handler flows to test specific scenarios:
///
/// ```swift
/// let customFlow = ChargeSimulator.RequestHandlers(
///     siteProvider: .demoSite, // Or: .live
///     onStartRequest: {
///         // Custom start logic - could throw errors, add delays, etc.
///     },
///     onStopRequest: { context in
///         // Custom stop logic with access to session context
///     },
///     onSessionPolling: { context in
///         // Custom status transition logic
///         switch context.currentStatus {
///         case .startRequested:
///             return .started // Immediate transition
///         case .started:
///             return context.secondsSinceLastStatusChange > 5 ? .charging : nil
///         // ... more status transitions
///         }
///     }
/// )
///
/// ChargeSimulator.configure(flow: customFlow)
/// ```
///
/// ## Context and State Management
///
/// The simulator maintains session context including:
/// - Current session status and timing information
/// - User requests (start/stop)
/// - Charge consumption and duration calculations
/// - Historical data like when statuses last changed
///
/// This context is passed to request handlers so they can make intelligent decisions about status
/// transitions
/// and responses based on the current session state.
///
/// ## Integration
///
/// The simulator is only enabled when the SDK is initialized with a `.simulator` configuration
/// using`Elvah.initialize(with: .simulator)`. When active, it automatically intercepts all SDK
/// network requests.
///
/// The simulator must be configured at every app launch, after initializing the SDK with the
/// simulator configuration.
/// No changes to your app code are required beyond the initial setup - simply configure the
/// simulator and use the SDK normally.
@_spi(Debug)
public actor ChargeSimulator {
	package static let shared = ChargeSimulator()

	/// Internal storage of the simulated charge session data.
	private var _context: Context?

	/// Configuration of the charge simulator.
	private var configuration: Configuration = .init()

	/// The request handlers defining the behavior of the charge simulator.
	private var requests: RequestHandlers = .default

	/// Maps signed-offer tokens to their ChargeOffer.
	var offersByToken: [String: ChargeOffer] = [:]

	/// Maps evse ids to their charge offer.
	var offersByEvseId: [String: ChargeOffer] = [:]

	package init() {
		_context = Defaults[.simulationContext]
	}

	/// Configures the charge simulator with a specific request handler flow and optional settings.
	///
	/// The simulator intercepts network requests and replaces them with configurable behaviors,
	/// allowing you to test various charge scenarios including successful flows, failures, and edge
	/// cases.
	///
	/// - Parameters:
	///   - requestHandlers: The request handler flow defining simulator behavior. Defaults to
	/// `.default`.
	///   - block: Optional configuration block for customizing response delays and other settings.
	public static func configure(
		flow requestHandlers: RequestHandlers = .default,
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
			session: ChargeSession(evseId: chargeOffer.evseId)
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

		let sites: [ChargeSite]

		if let region {
			sites = try await requests.siteProvider.sites(in: region, onlyCampaigns: onlyCampaigns)
		} else if let evseIds {
			sites = try await requests.siteProvider.sites(
				forEvseIds: evseIds,
				onlyCampaigns: onlyCampaigns
			)
		} else {
			throw NetworkError.unexpectedServerResponse
		}

		// Save offers for signing them later
		for offer in sites.flatMap(\.offers) {
			offersByEvseId[offer.evseId] = offer
		}

		return sites
	}

	package func signOffer(siteId: String, evseId: String) async throws -> SignedChargeOffer {
		try await delay()

		guard let offer = offersByEvseId[evseId] else {
			throw NetworkError.unexpectedServerResponse
		}

		let signedOffer = SignedChargeOffer(
			offer: offer,
			token: UUID().uuidString,
			validUntil: Date().addingTimeInterval(60 * 5)
		)

		offersByToken[signedOffer.token] = signedOffer.offer
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

		guard let chargeOffer = offersByToken[authentication.token] else {
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
			context.secondsSinceLastStatusChange = Date().timeIntervalSince(context.statusLastChangedAt)
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
		public package(set) var secondsSinceLastStatusChange: TimeInterval = 0

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
	/// Defines the behavior of the charge simulator through a set of request handler closures.
	///
	/// The `RequestHandlers` struct contains closures that intercept and respond to different types
	/// of network requests during a charge session simulation. Each handler allows you to customize
	/// the simulator's behavior for specific scenarios like successful flows, failures, or edge cases.
	///
	/// ## Handler Types
	///
	/// ### Site Provider
	/// Determines how charge sites are discovered and returned. Can use live API data, demo data,
	/// or custom implementations.
	///
	/// ### Start Request Handler
	/// Called when a charge session start is requested. This is where you can simulate start
	/// failures, delays, or custom validation logic.
	///
	/// ### Stop Request Handler
	/// Called when a charge session stop is requested. Receives the current session context,
	/// allowing you to make decisions based on the session's current state.
	///
	/// ### Session Polling Handler
	/// Called repeatedly (approximately every 2 seconds) during
	/// the charge session to determine status transitions. This handler receives the current
	/// session context and should return the next status the session should transition to,
	/// or `nil` if no transition should occur.
	struct RequestHandlers: Sendable {
		/// Closure type for handling charge session start requests.
		///
		/// This closure is called when the SDK requests to start a charge session. It can throw
		/// errors to simulate start failures or perform async operations to simulate delays.
		///
		/// - Throws: Any error to simulate a failed start request
		public typealias StartRequest = @Sendable () async throws -> Void
		
		/// Closure type for handling charge session stop requests.
		///
		/// This closure is called when the SDK requests to stop a charge session. It receives
		/// the current session context, allowing you to make decisions based on the session's
		/// current state, duration, or other factors.
		///
		/// - Parameter session: The current session context containing status, timing, and request information
		/// - Throws: Any error to simulate a failed stop request
		public typealias StopRequest = @Sendable (_ session: Context) async throws -> Void
		
		/// Closure type for handling session status polling.
		///
		/// The SDK calls this closure regularly (approximately every 2 seconds) during an active
		/// charge session to determine if the session status should change. The closure receives
		/// detailed context about the current session state and should return:
		///
		/// - A new `ChargeSession.Status` if the session should transition to that status
		/// - `nil` if the session should remain in its current status
		///
		/// ## Context Information Available
		///
		/// The `session` parameter provides access to:
		/// - `currentStatus`: The session's current status
		/// - `currentRequest`: Any pending user requests (start/stop)
		/// - `elapsedSeconds`: Total time since session started
		/// - `secondsSinceLastStatusChange`: Time since the last status transition
		/// - `secondsSinceLastPolling`: Time since the last polling call
		///
		/// ## Example Usage
		///
		/// ```swift
		/// onSessionPolling: { context in
		///     switch context.currentStatus {
		///     case .startRequested:
		///         // Immediately transition to started
		///         return .started
		///         
		///     case .started:
		///         // Wait 3 seconds before starting to charge
		///         return context.secondsSinceLastStatusChange > 3 ? .charging : nil
		///         
		///     case .charging:
		///         // If user requested stop, transition to stopRequested
		///         if context.currentRequest == .stopRequested {
		///             return .stopRequested
		///         }
		///         // Otherwise keep charging
		///         return nil
		///         
		///     case .stopRequested:
		///         // Wait 2 seconds then stop
		///         return context.secondsSinceLastStatusChange > 2 ? .stopped : nil
		///         
		///     case .stopped:
		///         // Session is finished, no more transitions
		///         return nil
		///         
		///     default:
		///         return nil
		///     }
		/// }
		/// ```
		///
		/// - Parameter session: The current session context with timing and status information
		/// - Returns: The next status to transition to, or `nil` to remain in the current status
		/// - Throws: Any error to simulate polling failures
		public typealias SessionRequest = @Sendable (
			_ session: Context
		) async throws -> ChargeSession.Status?

		package var siteProvider: SiteProvider
		package var onStartRequest: StartRequest
		package var onStopRequest: StopRequest
		package var onSessionPolling: SessionRequest

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
