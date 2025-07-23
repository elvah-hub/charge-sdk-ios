// Copyright © elvah. All rights reserved.

import CoreLocation
import MapKit
import SwiftUI

public extension ChargeSite {

	@MainActor fileprivate static var discoveryProvider: DiscoveryProvider {
		if Elvah.configuration.environment.isSimulation {
			return  DiscoveryProvider.simulation
		} else {
			return DiscoveryProvider.live
		}
	}

	// MARK: - By Evse Ids

	/// Returns all charge sites for the given list of evse ids.
	///
	/// - Note: Unsupported evse ids will be ignored.
	/// - Parameter evseIds: The evse ids.
	@MainActor static func sites(forEvseIds evseIds: [String]) async throws(Elvah
		.Error
	) -> [ChargeSite] {
		do {
			return try await discoveryProvider.sites(forEvseIds: evseIds)
		} catch NetworkError.unauthorized {
			throw Elvah.Error.unauthorized
		} catch let error as NetworkError {
			throw Elvah.Error.network(error)
		} catch {
			throw Elvah.Error.unknown(error)
		}
	}

	/// Returns all charge sites for the given list of evse ids.
	///
	/// - Note: Unsupported evse ids will be ignored.
	/// - Parameter evseIds: The evse ids.
	/// - Parameter completion: A closure that is called with the result of the operation.
	/// - Returns: An observer object that you can use to cancel the operation.
	@MainActor @discardableResult static func sites(
		forEvseIds evseIds: [String],
		completion: @MainActor @escaping (
			_ result: Result<[ChargeSite], Elvah.Error>
		) -> Void
	) -> TaskObserver {
		let task = Task {
			do {
				try await completion(.success(sites(forEvseIds: evseIds)))
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

	// MARK: - By Region

	/// Returns all charge sites within the given map region.
	/// - Parameter region: The region to search charge sites in.
	@MainActor static func sites(in region: MKMapRect) async throws(Elvah.Error) -> [ChargeSite] {
		do {
			return try await discoveryProvider.sites(in: region)
		} catch NetworkError.unauthorized {
			throw Elvah.Error.unauthorized
		} catch let error as NetworkError {
			throw Elvah.Error.network(error)
		} catch {
			throw Elvah.Error.unknown(error)
		}
	}

	/// Returns all charge sites within the given map region.
	/// - Parameter region: The region to search charge sites in.
	/// - Parameter completion: A closure that is called with the result of the operation.
	/// - Returns: An observer object that you can use to cancel the operation.
	@MainActor @discardableResult static func sites(
		in region: MKMapRect,
		completion: @MainActor @escaping (
			_ result: Result<[ChargeSite], Elvah.Error>
		) -> Void
	) -> TaskObserver {
		let task = Task {
			do {
				try await completion(.success(sites(in: region)))
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

	// MARK: - By Location

	/// Returns all charge sites near the given location.
	/// - Parameter location: The location to search charge sites nearby of.
	@MainActor static func sites(
		near location: CLLocationCoordinate2D
	) async throws(Elvah.Error) -> [ChargeSite] {
		do {
			return try await discoveryProvider.sites(near: location)
		} catch NetworkError.unauthorized {
			throw Elvah.Error.unauthorized
		} catch let error as NetworkError {
			throw Elvah.Error.network(error)
		} catch {
			throw Elvah.Error.unknown(error)
		}
	}

	/// Returns all charge sites near the given location.
	/// - Parameter location: The location to search charge sites nearby of.
	/// - Parameter completion: A closure that is called with the result of the operation.
	/// - Returns: An observer object that you can use to cancel the operation.
	@MainActor @discardableResult static func sites(
		near location: CLLocationCoordinate2D,
		completion: @MainActor @escaping (
			_ result: Result<[ChargeSite], Elvah.Error>
		) -> Void
	) -> TaskObserver {
		let task = Task {
			do {
				try await completion(.success(sites(near: location)))
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

// MARK: - Campaigns

public extension ChargeSite {
	// MARK: - By Region

	/// Returns all campaigns within the given map region.
	/// - Parameter region: The region to search campaigns in.
	@MainActor static func campaigns(in region: MKMapRect) async throws(Elvah.Error) -> [ChargeSite] {
		do {
			return try await discoveryProvider.campaigns(in: region)
		} catch NetworkError.unauthorized {
			throw Elvah.Error.unauthorized
		} catch let error as NetworkError {
			throw Elvah.Error.network(error)
		} catch {
			throw Elvah.Error.unknown(error)
		}
	}

	/// Returns all campaigns within the given map region.
	/// - Parameter region: The region to search campaigns in.
	/// - Parameter completion: A closure that is called with the result of the operation.
	/// - Returns: An observer object that you can use to cancel the operation.
	@MainActor @discardableResult static func campaigns(
		in region: MKMapRect,
		completion: @MainActor @escaping (
			_ result: Result<[ChargeSite], Elvah.Error>
		) -> Void
	) -> TaskObserver {
		let task = Task {
			do {
				try await completion(.success(campaigns(in: region)))
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

	// MARK: - By Location

	/// Returns all campaigns near the given location.
	/// - Parameter location: The location to search campaigns nearby of.
	@MainActor static func campaigns(
		near location: CLLocationCoordinate2D
	) async throws(Elvah.Error) -> [ChargeSite] {
		do {
			return try await discoveryProvider.campaigns(near: location)
		} catch NetworkError.unauthorized {
			throw Elvah.Error.unauthorized
		} catch let error as NetworkError {
			throw Elvah.Error.network(error)
		} catch {
			throw Elvah.Error.unknown(error)
		}
	}

	/// Returns all campaigns near the given location.
	/// - Parameter location: The location to search campaigns nearby of.
	/// - Parameter completion: A closure that is called with the result of the operation.
	/// - Returns: An observer object that you can use to cancel the operation.
	@MainActor @discardableResult static func campaigns(
		near location: CLLocationCoordinate2D,
		completion: @MainActor @escaping (
			_ result: Result<[ChargeSite], Elvah.Error>
		) -> Void
	) -> TaskObserver {
		let task = Task {
			do {
				try await completion(.success(campaigns(near: location)))
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

