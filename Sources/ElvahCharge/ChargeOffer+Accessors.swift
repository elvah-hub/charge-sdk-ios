// Copyright © elvah. All rights reserved.

import CoreLocation
import MapKit
import SwiftUI

public extension ChargeOffer {
  @MainActor fileprivate static var discoveryProvider: DiscoveryProvider {
    if Elvah.configuration.environment.isSimulation {
      DiscoveryProvider.simulation
    } else {
      DiscoveryProvider.live
    }
  }

  /// Returns all charge offers for the given list of evse ids.
  ///
  /// - Note: Unsupported evse ids will be ignored.
  /// - Parameter evseIds: The evse ids.
  /// - Returns: An instance of ``ChargeOfferList`` that contains all the found charge points.
  @MainActor static func offers(
    forEvseIds evseIds: [String],
  ) async throws(Elvah.Error) -> ChargeOfferList {
    do {
      let chargeSites = try await discoveryProvider.sites(forEvseIds: evseIds)
      let offers = chargeSites.flatMap(\.offers)
      return ChargeOfferList(offers: offers)
    } catch NetworkError.unauthorized {
      throw Elvah.Error.unauthorized
    } catch let error as NetworkError {
      throw Elvah.Error.network(error)
    } catch {
      throw Elvah.Error.unknown(error)
    }
  }

  /// Returns all charge offers for the given list of evse ids.
  ///
  /// - Note: Unsupported evse ids will be ignored.
  /// - Parameter evseIds: The evse ids.
  /// - Parameter completion: A closure that is called with the result of the operation.
  /// - Returns: An observer object that you can use to cancel the operation.
  @MainActor @discardableResult static func offers(
    forEvseIds evseIds: [String],
    completion: @MainActor @escaping (
      _ result: Result<ChargeOfferList, Elvah.Error>
    ) -> Void,
  ) -> TaskObserver {
    let task = Task {
      do {
        try await completion(.success(offers(forEvseIds: evseIds)))
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
