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
	/// - Note: You can also use ``ChargeSite/pricingSchedule()``.
	/// - Parameter chargeSite: The charge site to load the schedule for.
	/// - Returns: The pricing schedule for the charge site.
	@MainActor static func schedule(
		for chargeSite: ChargeSite
	) async throws(Elvah.Error) -> ChargeSiteSchedule {
		do {
			let schedule = try await discoveryProvider.pricingSchedule(siteId: chargeSite.id)
			return ChargeSiteSchedule(chargeSite: chargeSite, pricingSchedule: schedule)
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
	/// - Note: You can also use ``ChargeSite/pricingSchedule()``.
	/// - Parameters:
	///   - chargeSite: The charge site to load the schedule for.
	///   - completion: A closure called with the result of the operation.
	/// - Returns: An observer you can use to cancel the operation.
	@MainActor @discardableResult static func schedule(
		for chargeSite: ChargeSite,
		completion: @MainActor @escaping (_ result: Result<ChargeSiteSchedule, Elvah.Error>) -> Void
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

public extension ChargeSite {
	/// Loads the pricing schedule for this charge site.
	///
	/// You can also use ``PricingSchedule/schedule(for:)``.
	func pricingSchedule() async throws -> ChargeSiteSchedule {
		try await PricingSchedule.schedule(for: self)
	}
}
