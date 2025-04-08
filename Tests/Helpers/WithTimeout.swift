// Copyright © elvah. All rights reserved.

import Foundation

@available(iOS 16.0, *) func withTimeout<T: Sendable>(
	duration: Duration,
	operation: @Sendable @escaping () async throws -> T
) async throws -> T {
	try await withThrowingTaskGroup(of: T.self) { group in
		group.addTask {
			try await operation()
		}
		group.addTask {
			try await Task.sleep(for: duration)
			throw TimeoutError()
		}
		let result = try await group.next()!
		group.cancelAll()
		return result
	}
}
