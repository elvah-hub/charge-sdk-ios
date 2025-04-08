// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Get)
	import Get
#endif

final class ChargeService: Sendable {
	private static let serviceName = "Charge"
	private let client: NetworkClient
	private let apiKey: String
	private let environment: BackendEnvironment

	init(apiKey: String, environment: BackendEnvironment) {
		self.apiKey = apiKey
		self.environment = environment

		let baseURL = environment.urlForService()
		client = .init(baseURL: baseURL, environment: environment)
	}

	func start(authentication: ChargeAuthentication) async throws(NetworkError) {
		do {
			let request = Request<Void>(
				path: "/direct-charge/user/session/start",
				method: .get
			)

			try await client.send(request) { [apiKey] request in
				request.setAPIKey(apiKey)
				request.setBearerToken(authentication.token)
			}
		} catch {
			logCommonNetworkError(error, name: Self.serviceName)
			throw error.externalError
		}
	}

	func session(authentication: ChargeAuthentication) async throws(NetworkError) -> ChargeSession {
		do {
			let request = Request<ChargeSessionResponseBody>(
				path: "/direct-charge/user/session",
				method: .get
			)

			let response = try await client.send(request) { [apiKey] request in
				request.setAPIKey(apiKey)
				request.setBearerToken(authentication.token)
			}

			return try ChargeSession.parse(response.value.data)
		} catch let error as NetworkError.Client {
			logCommonNetworkError(error, name: Self.serviceName)
			throw error.externalError
		} catch {
			logCommonNetworkError(error, name: Self.serviceName)
			throw NetworkError.unknown
		}
	}

	func stop(authentication: ChargeAuthentication) async throws(NetworkError) {
		do {
			let request = Request<Void>(
				path: "/direct-charge/user/session/stop",
				method: .get
			)

			try await client.send(request) { [apiKey] request in
				request.setAPIKey(apiKey)
				request.setBearerToken(authentication.token)
			}
		} catch {
			logCommonNetworkError(error, name: Self.serviceName)
			throw error.externalError
		}
	}
}

private extension ChargeService {
	struct CommandStartRequestBody: Encodable {
		let connectorType: String?
		let evseId: String
		let signedTariffOffer: String
	}

	struct ChargeSessionResponseBody: Decodable {
		var data: ChargeSessionSchema
	}

	struct CommandStopRequestBody: Encodable {
		let chargeSessionId: String
	}
}
