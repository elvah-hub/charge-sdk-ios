// Copyright © elvah. All rights reserved.

import MapKit
import SwiftUI

#if canImport(Get)
	import Get
#endif

final class DiscoveryService: Sendable {
	private static let serviceName = "Discovery"
	private let client: NetworkClient
	private let apiKey: String
	private let environment: BackendEnvironment

	init(apiKey: String, environment: BackendEnvironment) {
		self.apiKey = apiKey
		self.environment = environment

		let baseURL = environment.urlForService()
		client = .init(baseURL: baseURL, environment: environment)
	}

	func deals(in region: MKMapRect) async throws(NetworkError) -> [Campaign] {
		let topLeft = MKMapPoint(x: region.origin.x, y: region.origin.y).coordinate
		let bottomRight = MKMapPoint(x: region.maxX, y: region.maxY).coordinate

		let query = [
			("minLat", "\(bottomRight.latitude)"),
			("minLng", "\(topLeft.longitude)"),
			("maxLat", "\(topLeft.latitude)"),
			("maxLng", "\(bottomRight.longitude)"),
		]

		do {
			let request = Request<DealsResponse>(path: "/discovery/deals", method: .get, query: query)
			let response = try await client.send(request) { [apiKey] request in
				request.setAPIKey(apiKey)
			}
			return try response.value.data.map { try Campaign.parse($0) }
		} catch let error as NetworkError.Client {
			logCommonNetworkError(error, name: Self.serviceName)
			throw error.externalError
		} catch {
			logCommonNetworkError(error, name: Self.serviceName)
			throw NetworkError.unknown
		}
	}
}

private struct DealsResponse: Decodable {
	var data: [CampaignSchema]
}
