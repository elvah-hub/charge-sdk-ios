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

	func siteOffers(forEvseIds evseIds: [String]) async throws(NetworkError) -> [ChargeSite] {
		let query = evseIds.map { ("evseIds", $0) }

		do {
			let request = Request<SiteOffersResponse>(path: "/discovery/sites-offers", method: .get, query: query)
			let response = try await client.send(request) { [apiKey] request in
				request.setValue(Elvah.distinctId.rawValue, forHTTPHeaderField: "X-Distinct-Id")
				request.setAPIKey(apiKey)
			}
			return try response.value.data.map { try ChargeSite.parse($0) }
		} catch let error as NetworkError.Client {
			logCommonNetworkError(error, name: Self.serviceName)
			throw error.externalError
		} catch {
			logCommonNetworkError(error, name: Self.serviceName)
			throw NetworkError.unknown
		}
	}

	func siteOffers(in region: MKMapRect) async throws(NetworkError) -> [ChargeSite] {
		let topLeft = MKMapPoint(x: region.origin.x, y: region.origin.y).coordinate
		let bottomRight = MKMapPoint(x: region.maxX, y: region.maxY).coordinate

		let query = [
			("minLat", "\(bottomRight.latitude)"),
			("minLng", "\(topLeft.longitude)"),
			("maxLat", "\(topLeft.latitude)"),
			("maxLng", "\(bottomRight.longitude)"),
		]

		do {
			let request = Request<SiteOffersResponse>(path: "/discovery/sites-offers", method: .get, query: query)
			let response = try await client.send(request) { [apiKey] request in
				request.setValue(Elvah.distinctId.rawValue, forHTTPHeaderField: "X-Distinct-Id")
				request.setAPIKey(apiKey)
			}
			return try response.value.data.map { try ChargeSite.parse($0) }
		} catch let error as NetworkError.Client {
			logCommonNetworkError(error, name: Self.serviceName)
			throw error.externalError
		} catch {
			logCommonNetworkError(error, name: Self.serviceName)
			throw NetworkError.unknown
		}
	}
}

private struct SiteOffersResponse: Decodable {
	var data: [SiteOfferSchema]
}
