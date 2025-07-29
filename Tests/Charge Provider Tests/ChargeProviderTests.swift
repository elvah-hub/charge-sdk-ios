// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

@Suite("Charge Provider Tests")
@MainActor
struct ChargeProviderTests {
	@available(iOS 16.0, *) typealias Stream = ChargeProvider.SessionUpdateStream

	@Test("Shared session updates with single subscription") @available(iOS 16.0, *) func testSharedSessionUpdates() async throws {
		let subscriptionManager = ChargeProvider.SubscriptionManager()
		let authentication = ChargeAuthentication(token: "token", expiryDate: nil)

		let simulator = ChargeSessionSimulator(
			session: ChargeSession(
				evseId: "evseId",
				status: .charging,
				consumption: 42,
				duration: 0
			)
		)

		let provider = ChargeProvider(
			dependencies: ChargeProvider.Dependencies(
				subscriptionManager: subscriptionManager,
				session: { _ in
					try await simulator.fetchSession()
				},
				start: { _ in },
				stop: { _ in }
			)
		)

		// Make sure the subscription manager is empty for now
		await #expect(subscriptionManager.subscribers().isEmpty)
		await #expect(subscriptionManager.hasSubscribers() == false)

		// Create a subscriber
		var streamA: Stream? = await provider.sharedSessionUpdates(with: authentication)

		// Make sure the subscription manager is correct
		await #expect(subscriptionManager.subscribers().count == 1)
		await #expect(subscriptionManager.hasSubscribers() == true)

		// Observe the session
		await #expect(throws: Never.self) {
			for try await newSession in await streamA! {
				#expect(newSession.evseId == "evseId")
				#expect(newSession.duration == 0)
				break
			}
		}

		// Advance session
		await simulator.advanceSession(by: 1)

		// Observe it again
		await #expect(throws: Never.self) {
			for try await newSession in await streamA! {
				#expect(newSession.evseId == "evseId")
				#expect(newSession.duration == 1)
				break
			}
		}

		// Make sure the session has been fetched exactly twice
		await #expect(simulator.metrics.fetchCount == 2)

		// Remove the stream
		streamA = nil

		// Wait for internal cleanup
		await #expect(throws: Never.self) {
			try await subscriptionManager.waitForSubscriberCount(0, timeout: .milliseconds(500))
		}

		// Make sure the subscriber has been removed
		await #expect(subscriptionManager.subscribers().isEmpty)
		await #expect(subscriptionManager.hasSubscribers() == false)
	}

	@Test("Shared session updates with multiple subscriptions") @available(iOS 16.0, *)
	func testSharedSessionUpdatesWithMultipleSubscriptions() async throws {
		let subscriptionManager = ChargeProvider.SubscriptionManager()
		let authentication = ChargeAuthentication(token: "token", expiryDate: nil)

		let simulator = ChargeSessionSimulator(
			session: ChargeSession(
				evseId: "evseId",
				status: .charging,
				consumption: 42,
				duration: 0
			)
		)

		let provider = ChargeProvider(
			dependencies: ChargeProvider.Dependencies(
				subscriptionManager: subscriptionManager,
				session: { _ in
					try await simulator.fetchSession()
				},
				start: { _ in },
				stop: { _ in }
			)
		)

		// Spawn 3 tasks that each subscribe to shared session updates
		let taskA = Task {
			var count = 0
			await #expect(throws: Never.self) {
				for try await _ in await provider.sharedSessionUpdates(with: authentication) {
					if count == 2 {
						break
					}
					count += 1
				}
			}
		}

		let taskB = Task {
			var count = 0
			await #expect(throws: Never.self) {
				for try await _ in await provider.sharedSessionUpdates(with: authentication) {
					if count == 2 {
						break
					}
					count += 1
				}
			}
		}

		let taskC = Task {
			var count = 0
			await #expect(throws: Never.self) {
				for try await _ in await provider.sharedSessionUpdates(with: authentication) {
					if count == 2 {
						break
					}
					count += 1
				}
			}
		}

		// Wait for the completion of all tasks
		_ = await taskA.value
		_ = await taskB.value
		_ = await taskC.value

		// Wait to allow subscriber manager to clean up all subscribers, which happens asynchronously
		await #expect(throws: Never.self) {
			try await subscriptionManager.waitForSubscriberCount(0, timeout: .milliseconds(500))
		}

		// Now make sure that the session has only been fetched three times, not nine times
		await #expect(simulator.metrics.fetchCount == 3)
	}

	@Test("Shared session update polling restart after subscription removal") @available(iOS 16.0, *) func testSharedSessionUpdatePollingRestart() async throws {
		let subscriptionManager = ChargeProvider.SubscriptionManager()
		let authentication = ChargeAuthentication(token: "token", expiryDate: nil)

		let simulator = ChargeSessionSimulator(
			session: ChargeSession(
				evseId: "evseId",
				status: .charging,
				consumption: 42,
				duration: 0
			)
		)

		let provider = ChargeProvider(
			dependencies: ChargeProvider.Dependencies(
				subscriptionManager: subscriptionManager,
				session: { _ in
					try await simulator.fetchSession()
				},
				start: { _ in },
				stop: { _ in }
			)
		)

		// Create a subscriber
		var streamA: Stream? = await provider.sharedSessionUpdates(with: authentication)

		// Observe for one iteration
		for try await session in streamA! {
			#expect(session.evseId == "evseId")
			break
		}

		// Make sure the backend was called once
		await #expect(simulator.metrics.fetchCount == 1)

		// Make sure the subscription manager is correct
		await #expect(subscriptionManager.subscribers().count == 1)
		await #expect(subscriptionManager.hasSubscribers() == true)

		// Remove subscriber
		streamA = nil

		// Wait for internal cleanup
		await #expect(throws: Never.self) {
			try await subscriptionManager.waitForSubscriberCount(0, timeout: .milliseconds(500))
		}

		// Make sure the subscription manager is back to 0
		await #expect(subscriptionManager.subscribers().isEmpty)
		await #expect(subscriptionManager.hasSubscribers() == false)

		// Create a new subscriber
		let streamB = await provider.sharedSessionUpdates(with: authentication)

		// Observe for one iteration to make sure a new session is being fetched
		for try await session in streamB {
			#expect(session.evseId == "evseId")
			break
		}

		// Make sure the backend call count has indeed increased
		await #expect(simulator.metrics.fetchCount == 2)
	}

	@Test("Shared session updates with many concurrent subscriptions") @available(iOS 16.0, *) func testSharedSessionUpdatesSpam() async throws {
		let subscriptionManager = ChargeProvider.SubscriptionManager()
		let authentication = ChargeAuthentication(token: "token", expiryDate: nil)

		let simulator = ChargeSessionSimulator(
			session: ChargeSession(
				evseId: "evseId",
				status: .charging,
				consumption: 42,
				duration: 0
			)
		)

		let provider = ChargeProvider(
			dependencies: ChargeProvider.Dependencies(
				subscriptionManager: subscriptionManager,
				session: { _ in
					try await simulator.fetchSession()
				},
				start: { _ in },
				stop: { _ in }
			)
		)

		// Spawn lots of subscribers and wait for them to be done
		try await withThrowingTaskGroup { group in
			for _ in 0 ..< 10 {
				group.addTask {
					for try await _ in await provider.sharedSessionUpdates(with: authentication) {
						break
					}
				}
			}

			try await group.waitForAll()
		}

		await #expect(throws: Never.self) {
			try await subscriptionManager.waitForSubscriberCount(0, timeout: .milliseconds(500))
		}

		await #expect(simulator.metrics.fetchCount == 1)
	}

	// MARK: - Failure Cases

	@Test("Shared session updates handles network failures and recovery") @available(iOS 16.0, *) func testSharedSessionUpdatesWithBasicFailure() async throws {
		let subscriptionManager = ChargeProvider.SubscriptionManager()
		let authentication = ChargeAuthentication(token: "token", expiryDate: nil)

		let simulator = ChargeSessionSimulator(
			session: ChargeSession(
				evseId: "evseId",
				status: .charging,
				consumption: 42,
				duration: 0
			)
		)

		let provider = ChargeProvider(
			dependencies: ChargeProvider.Dependencies(
				subscriptionManager: subscriptionManager,
				session: { _ in
					try await simulator.fetchSession()
				},
				start: { _ in },
				stop: { _ in }
			)
		)

		// Configure the simulator to throw an error
		await simulator.updateConfiguration { configuration in
			configuration.fetchBehavior = .fail(.server)
		}

		// Observe the session
		try await #require(throws: NetworkError.server) {
			for try await _ in await provider.sharedSessionUpdates(with: authentication) {
				// This should not reach here
				Issue.record("Expected a network error but received a session!")
				break
			}
		}

		// Wait for internal cleanup
		await #expect(throws: Never.self) {
			try await subscriptionManager.waitForSubscriberCount(0, timeout: .milliseconds(500))
		}

		// Then try again to make sure it restarts the polling tasks and still fails
		try await #require(throws: NetworkError.server) {
			for try await _ in await provider.sharedSessionUpdates(with: authentication) {
				// This should not reach here
				Issue.record("Expected a network error but received a session!")
				break
			}
		}

		// Now make the simulated backend work again
		await simulator.updateConfiguration { configuration in
			configuration.fetchBehavior = .allow
		}

		// Observe again and make sure that the stream is emitting a value again
		let stream = await provider.sharedSessionUpdates(with: authentication)
		await #expect(throws: Never.self) {
			try await withTimeout(duration: .seconds(1)) {
				for try await newSession in await stream {
					#expect(newSession.evseId == "evseId")
					break
				}
			}
		}
	}
}
