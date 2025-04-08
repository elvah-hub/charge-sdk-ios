// Copyright © elvah. All rights reserved.

import SwiftUI

@MainActor
final class ChargeProvider: ObservableObject {
	package typealias SessionUpdateStream = AsyncThrowingStream<ChargeSession, any Swift.Error>

	struct Dependencies: Sendable {
		var subscriptionManager: SubscriptionManager
		var session: @Sendable (_ authentication: ChargeAuthentication) async throws -> ChargeSession
		var start: @Sendable (_ authentication: ChargeAuthentication) async throws -> Void
		var stop: @Sendable (_ authentication: ChargeAuthentication) async throws -> Void
	}

	private let dependencies: Dependencies

	private var sharedSessionUpdatesTask: Task<Void, Never>?
	private var sharedSessionUpdatesPollingEnabled = false
	private var subscriptionManager: SubscriptionManager {
		dependencies.subscriptionManager
	}

	nonisolated init(dependencies: Dependencies) {
		self.dependencies = dependencies
	}

	func session(
		authentication: ChargeAuthentication
	) async throws -> ChargeSession {
		try await dependencies.session(authentication)
	}

	func start(
		authentication: ChargeAuthentication
	) async throws {
		try await dependencies.start(authentication)
	}

	func stop(
		authentication: ChargeAuthentication
	) async throws {
		try await dependencies.stop(authentication)
	}

	// MARK: - Shared Session Polling

	func sharedSessionUpdates(
		with authentication: ChargeAuthentication
	) async -> SessionUpdateStream {
		let id = UUID()
		let (stream, continuation) = SessionUpdateStream
			.makeStream(bufferingPolicy: .bufferingNewest(1))

		// Setup termination logic
		continuation.onTermination = { [subscriptionManager] _ in
			Task {
				await subscriptionManager.removeSubscriber(withId: id)
			}
		}

		// Add subscription
		await subscriptionManager.addSubscriber(withId: id, continuation: continuation)

		// Start polling if this is the first subscription
		if sharedSessionUpdatesPollingEnabled == false {
			startPolling(with: authentication)
		}

		return stream
	}

	/// Starts a polling task that periodically fetches charge session information from the backend
	/// whenever there a consumers for this data.
	/// - Parameter authentication: The authentication needed to fetch the charge session from the
	/// backend.
	private func startPolling(with authentication: ChargeAuthentication) {
		sharedSessionUpdatesPollingEnabled = true
		sharedSessionUpdatesTask?.cancel()
		sharedSessionUpdatesTask = Task {
			Elvah.internalLogger.debug("Starting charge session polling task")
			while !Task.isCancelled {
				do {
					let session = try await session(authentication: authentication)
					let subscribers = await subscriptionManager.subscribers()

					// End this observation task if no subscribers are left
					if subscribers.isEmpty {
						Elvah.internalLogger.debug("No subscribers left, stopping polling task")
						sharedSessionUpdatesPollingEnabled = false
						return
					}

					// Yield the fetched charge session to all subscribers
					Elvah.internalLogger.debug("Yielding charge session to \(subscribers.count) subscribers")
					for subscriber in subscribers {
						subscriber.yield(session)
					}

					// Wait and repeat
					try await Task.sleep(nanoseconds: 2_000_000_000)
				} catch {
					// Yield error to all subscribers and exit the task
					Elvah.internalLogger.debug("Session fetch error, sending termination to all subscribers")
					for subscriber in await subscriptionManager.subscribers() {
						subscriber.finish(throwing: error)
					}

					sharedSessionUpdatesPollingEnabled = false
					Elvah.internalLogger.debug("Ending charge session polling task")
					return
				}
			}
		}
	}

	private func stopPolling() {
		sharedSessionUpdatesPollingEnabled = false
		sharedSessionUpdatesTask?.cancel()
		sharedSessionUpdatesTask = nil
	}
}

extension ChargeProvider {
	actor SubscriptionManager {
		typealias Continuation = ChargeProvider.SessionUpdateStream.Continuation

		private var continuations: [UUID: Continuation] = [:]
		init() {}

		func addSubscriber(withId id: UUID, continuation: Continuation) {
			continuations[id] = continuation
			log()
		}

		func removeSubscriber(withId id: UUID) {
			continuations.removeValue(forKey: id)
			log()
		}

		func subscribers() -> [Continuation] {
			Array(continuations.values)
		}

		func hasSubscribers() -> Bool {
			continuations.isEmpty == false
		}

		private func log() {
			let newCount = continuations.count
			Elvah.internalLogger.debug("Charge session update subscriptions: \(newCount)")
		}
	}
}

extension ChargeProvider {
	static let live = {
		let service = ChargeService(
			apiKey: Elvah.configuration.apiKey,
			environment: Elvah.configuration.environment
		)
		return ChargeProvider(
			dependencies: .init(
				subscriptionManager: ChargeProvider.SubscriptionManager(),
				session: { authentication in
					try await service.session(authentication: authentication)
				},
				start: { authentication in
					try await service.start(authentication: authentication)
				},
				stop: { authentication in
					try await service.stop(authentication: authentication)
				}
			)
		)
	}()

	@available(iOS 16.0, *) static let mock = mock(sessionStatus: .charging)

	@available(iOS 16.0, *) static func mock(sessionStatus: ChargeSession.Status) -> ChargeProvider {
		ChargeProvider(
			dependencies: .init(
				subscriptionManager: ChargeProvider.SubscriptionManager(),
				session: { authentication in
					try await Task.sleep(for: .milliseconds(200))
					return ChargeSession.mock(status: sessionStatus)
				},
				start: { authentication in
					try await Task.sleep(for: .milliseconds(200))
				},
				stop: { authentication in
					try await Task.sleep(for: .milliseconds(200))
				}
			)
		)
	}
}
