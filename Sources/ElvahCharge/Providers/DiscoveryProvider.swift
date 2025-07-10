// Copyright © elvah. All rights reserved.

import MapKit
import SwiftUI

@MainActor
final class DiscoveryProvider: ObservableObject {
	struct Dependencies: Sendable {
		var sitesForEvseIds: @Sendable (_ evseIds: [String]) async throws -> [ChargeSite]
		var sitesInRegion: @Sendable (_ region: MKMapRect) async throws -> [ChargeSite]
	}

	private let dependencies: Dependencies

	nonisolated init(dependencies: Dependencies) {
		self.dependencies = dependencies
	}

	func sites(forEvseIds evseIds: [String]) async throws -> [ChargeSite] {
		try await dependencies.sitesForEvseIds(evseIds)
	}

	func sites(in region: MKMapRect) async throws -> [ChargeSite] {
		try await dependencies.sitesInRegion(region)
	}

	func sites(near location: CLLocationCoordinate2D, radius: Double = 5) async throws -> [ChargeSite] {
		let region = MKMapRect.around(location, radius: radius)
		return try await dependencies.sitesInRegion(region)
	}

	func deals(in region: MKMapRect) async throws -> [ChargeSite] {
		try await dependencies.sitesInRegion(region)
	}

	func deals(near location: CLLocationCoordinate2D, radius: Double = 5) async throws -> [ChargeSite] {
		let region = MKMapRect.around(location, radius: radius)
		return try await dependencies.sitesInRegion(region)
	}
}

extension DiscoveryProvider {
	static let live = {
		let service = DiscoveryService(
			apiKey: Elvah.configuration.apiKey,
			environment: Elvah.configuration.environment
		)
		return DiscoveryProvider(
			dependencies: .init(
				sitesForEvseIds: { evseIds in
					try await service.siteOffers(forEvseIds: evseIds)
				},
				sitesInRegion: { region in
					try await service.siteOffers(in: region)
				}
			)
		)
	}()

	@available(iOS 16.0, *) static let mock = DiscoveryProvider(
		dependencies: .init(
			sitesForEvseIds: { evseIds in
				try await Task.sleep(for: .milliseconds(2000))
				return [ChargeSite.mock]
			},
			sitesInRegion: { region in
				try await Task.sleep(for: .milliseconds(2000))
				return [ChargeSite.mock]
			}
		)
	)
}
