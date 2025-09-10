// Copyright © elvah. All rights reserved.

import SwiftUI

public extension ChargeSiteSchedule {
	@MainActor fileprivate static var discoveryProvider: DiscoveryProvider {
		if Elvah.configuration.environment.isSimulation {
			DiscoveryProvider.simulation
		} else {
			DiscoveryProvider.live
		}
	}

	/// Loads the pricing schedule for a given charge site.
	///
	/// - Note: You can also use ``ChargeSite/pricingSchedule()``.
	/// - Parameter chargeSite: The charge site to load the schedule for.
	/// - Returns: The pricing schedule for the charge site.
	///
	/// Example
	/// ```swift
	/// let schedule = try await ChargeSiteSchedule.schedule(for: site)
	/// ```
	@MainActor static func schedule(
		for chargeSite: ChargeSite,
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
	///
	/// Example
	/// ```swift
	/// let observer = ChargeSiteSchedule.schedule(for: site) { result in
	///     // handle Result<ChargeSiteSchedule, Elvah.Error>
	/// }
	/// ```
	@MainActor @discardableResult static func schedule(
		for chargeSite: ChargeSite,
		completion: @MainActor @escaping (_ result: Result<ChargeSiteSchedule, Elvah.Error>) -> Void,
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
	/// You can also use ``ChargeSiteSchedule/schedule(for:)``.
	///
	/// Example
	/// ```swift
	/// let schedule = try await chargeSite.pricingSchedule()
	/// ```
	func pricingSchedule() async throws -> ChargeSiteSchedule {
		try await ChargeSiteSchedule.schedule(for: self)
	}
}
