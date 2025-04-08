// Copyright © elvah. All rights reserved.

import CoreLocation
import MapKit
import SwiftUI

public extension Campaign {
	// MARK: - By Region

	/// Returns all campaigns within the given map region.
	/// - Parameter region: The region to search campaigns in.
	@MainActor static func campaigns(in region: MKMapRect) async throws(Elvah.Error) -> [Campaign] {
		do {
			return try await DiscoveryProvider.live.deals(in: region)
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
			_ result: Result<[Campaign], Elvah.Error>
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
	) async throws(Elvah.Error) -> [Campaign] {
		do {
			return try await DiscoveryProvider.live.deals(near: location)
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
			_ result: Result<[Campaign], Elvah.Error>
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
