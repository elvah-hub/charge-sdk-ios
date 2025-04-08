// Copyright © elvah. All rights reserved.

import MapKit
import SwiftUI

@MainActor
final class DiscoveryProvider: ObservableObject {
	struct Dependencies: Sendable {
		var deals: @Sendable (_ region: MKMapRect) async throws -> [Campaign]
	}

	private let dependencies: Dependencies

	nonisolated init(dependencies: Dependencies) {
		self.dependencies = dependencies
	}

	func deals(in region: MKMapRect) async throws -> [Campaign] {
		try await dependencies.deals(region)
	}

	func deals(near location: CLLocationCoordinate2D, radius: Double = 5) async throws -> [Campaign] {
		let region = MKMapRect.around(location, radius: radius)
		return try await dependencies.deals(region)
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
				deals: { region in
					try await service.deals(in: region)
				}
			)
		)
	}()

	@available(iOS 16.0, *) static let mock = DiscoveryProvider(
		dependencies: .init(
			deals: { region in
				try await Task.sleep(for: .milliseconds(2000))
				return [Campaign.mock]
			}
		)
	)
}
