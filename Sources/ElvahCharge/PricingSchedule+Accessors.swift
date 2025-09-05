// Copyright © elvah. All rights reserved.

import SwiftUI

public extension PricingSchedule {
	@MainActor fileprivate static var discoveryProvider: DiscoveryProvider {
		if Elvah.configuration.environment.isSimulation {
			return DiscoveryProvider.simulation
		} else {
			return DiscoveryProvider.live
		}
	}

	/// Loads the pricing schedule for a given charge site.
	///
	/// - Parameter chargeSite: The charge site to load the schedule for.
	/// - Returns: The pricing schedule for the charge site.
	@MainActor static func schedule(
		for chargeSite: ChargeSite
	) async throws(Elvah.Error) -> PricingSchedule {
		do {
			return try await discoveryProvider.pricingSchedule(siteId: chargeSite.id)
		} catch NetworkError.unauthorized {
			throw Elvah.Error.unauthorized
		} catch let error as NetworkError {
			throw Elvah.Error.network(error)
		} catch {
			throw Elvah.Error.unknown(error)
		}
	}

	/// Loads the pricing schedule for a given charge site.
	///
	/// - Parameters:
	///   - chargeSite: The charge site to load the schedule for.
	///   - completion: A closure called with the result of the operation.
	/// - Returns: An observer you can use to cancel the operation.
	@MainActor @discardableResult static func schedule(
		for chargeSite: ChargeSite,
		completion: @MainActor @escaping (_ result: Result<PricingSchedule, Elvah.Error>) -> Void
	) -> TaskObserver {
		let task = Task {
			do {
				try await completion(.success(schedule(for: chargeSite)))
			} catch NetworkError.unauthorized {
				completion(.failure(Elvah.Error.unauthorized))
			} catch let error as NetworkError {
				completion(.failure(Elvah.Error.network(error)))
			} catch {
				completion(.failure(Elvah.Error.unknown(error)))
			}
		}

		return TaskObserver(task: task)
	}
}
