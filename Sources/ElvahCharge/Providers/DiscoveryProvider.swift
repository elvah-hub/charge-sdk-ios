// Copyright © elvah. All rights reserved.

import MapKit
import SwiftUI

@MainActor
final class DiscoveryProvider: ObservableObject {
	struct Dependencies: Sendable {
		var siteOffers: @Sendable (
			_ region: MKMapRect?,
			_ evseIds: [String]?,
			_ onlyCampaigns: Bool
		) async throws -> [ChargeSite]
		var signOffer: @Sendable (
			_ siteId: String,
			_ evseId: String
		) async throws -> SignedChargeOffer
	}

	private let dependencies: Dependencies

	nonisolated init(dependencies: Dependencies) {
		self.dependencies = dependencies
	}

	func sites(forEvseIds evseIds: [String]) async throws -> [ChargeSite] {
		try await dependencies.siteOffers(nil, evseIds, false)
	}

	func sites(in region: MKMapRect) async throws -> [ChargeSite] {
		try await dependencies.siteOffers(region, nil, false)
	}

	func sites(
		near location: CLLocationCoordinate2D,
		radius: Double = 20000
	) async throws -> [ChargeSite] {
		let region = MKMapRect.around(location, radius: radius)
		return try await dependencies.siteOffers(region, nil, false)
	}

	func campaigns(forEvseIds evseIds: [String]) async throws -> [ChargeSite] {
		try await dependencies.siteOffers(nil, evseIds, true)
	}

	func campaigns(in region: MKMapRect) async throws -> [ChargeSite] {
		try await dependencies.siteOffers(region, nil, true)
	}

	func campaigns(
		near location: CLLocationCoordinate2D,
		radius: Double = 20000
	) async throws -> [ChargeSite] {
		let region = MKMapRect.around(location, radius: radius)
		return try await dependencies.siteOffers(region, nil, true)
	}

	func signOffer(
		_ offer: ChargeOffer,
		in site: Site
	) async throws -> SignedChargeOffer {
		try await dependencies.signOffer(site.id, offer.evseId)
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
				siteOffers: { region, evseIds, onlyCampaigns in
					try await service.siteOffers(
						region: region,
						evseIds: evseIds,
						onlyCampaigns: onlyCampaigns
					)
				},
				signOffer: { siteId, evseId in
					try await service.signOffer(siteId: siteId, evseId: evseId)
				}
			)
		)
	}()

	@available(iOS 16.0, *) static let mock = DiscoveryProvider(
		dependencies: .init(
			siteOffers: { _, _, _ in
				try await Task.sleep(for: .milliseconds(2000))
				return [ChargeSite.mock]
			},
			signOffer: { _, _ in
				.mockAvailable
			}
		)
	)
}
