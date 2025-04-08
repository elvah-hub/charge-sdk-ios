// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation

@available(iOS 16.0, *)
actor ChargeSessionSimulator {
	private var session: ChargeSession
	var configuration: Configuration
	var metrics: Metrics

	init(
		session: ChargeSession,
		configuration: Configuration = Configuration()
	) {
		self.session = session
		self.configuration = configuration
		metrics = Metrics()
	}

	func fetchSession() async throws -> ChargeSession {
		metrics.fetchCount += 1

		switch configuration.fetchBehavior {
		case .allow:
			return session
		case let .fail(networkError):
			throw networkError
		}
	}

	func advanceSession(by duration: TimeInterval) {
		session.duration += duration
	}

	func updateConfiguration(block: @Sendable (_ configuration: inout Configuration) -> Void) {
		block(&configuration)
	}

	struct Metrics: Sendable {
		var fetchCount = 0
	}

	struct Configuration: Sendable {
		var fetchBehavior: FetchBehavior = .allow
	}

	enum FetchBehavior: Sendable {
		case allow
		case fail(NetworkError)
	}
}
