// Copyright © elvah. All rights reserved.

import MapKit
import SwiftUI

#if canImport(Get)
	import Get
#endif

final class DiscoveryService: Sendable {
	private let client: NetworkClient
	private let apiKey: String
	private let environment: BackendEnvironment

	init(apiKey: String, environment: BackendEnvironment) {
		self.apiKey = apiKey
		self.environment = environment

		let baseURL = environment.urlForService()
		client = .init(name: "Discovery", baseURL: baseURL, environment: environment)
	}

	func signOffer(siteId: String, evseId: String) async throws(NetworkError) -> SignedChargeOffer {
		do {
			let request = Request<SignedSiteOffersResponse>(
				path: "/discovery/sites-offers/\(siteId)",
				method: .post,
				body: SignedSiteOffersRequestBody(evseIds: [evseId])
			)

			let response = try await client.send(request) { [apiKey] request in
				request.setDistinctId(Elvah.distinctId.rawValue)
				request.setAPIKey(apiKey)
			}

			return try SignedChargeOffer.parseFromSiteOffer(response.value.data, evseId: evseId)
		} catch {
			throw error.externalError
		}
	}

	func siteOffers(forEvseIds evseIds: [String]) async throws(NetworkError) -> [ChargeSite] {
		let query = evseIds.map { ("evseIds", $0) }

		do {
			let request = Request<SiteOffersResponse>(
				path: "/discovery/sites-offers",
				method: .get,
				query: query
			)
			
			let response = try await client.send(request) { [apiKey] request in
				request.setDistinctId(Elvah.distinctId.rawValue)
				request.setAPIKey(apiKey)
			}

			var sites: [ChargeSite] = []
			for siteData in response.value.data {
				try sites.append(ChargeSite.parse(siteData))
			}
			return sites
		} catch {
			throw error.externalError
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
			let request = Request<SiteOffersResponse>(
				path: "/discovery/sites-offers",
				method: .get,
				query: query
			)

			let response = try await client.send(request) { [apiKey] request in
				request.setDistinctId(Elvah.distinctId.rawValue)
				request.setAPIKey(apiKey)
			}

			var sites: [ChargeSite] = []
			for siteData in response.value.data {
				try sites.append(ChargeSite.parse(siteData))
			}
			return sites
		} catch {
			throw error.externalError
		}
	}
}

private struct SignedSiteOffersRequestBody: Encodable {
	var evseIds: [String]
}

private struct SignedSiteOffersResponse: Decodable {
	var data: SiteOfferSchema
}

private struct SiteOffersResponse: Decodable {
	var data: [SiteOfferSchema]
}
