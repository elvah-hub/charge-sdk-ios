// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Get)
	import Get
#endif

final class ChargeSettlementService: Sendable {
	private static let serviceName = "ChargeSettlement"
	private let client: NetworkClient
	private let apiKey: String
	private let environment: BackendEnvironment

	init(apiKey: String, environment: BackendEnvironment) {
		self.apiKey = apiKey
		self.environment = environment

		let baseURL = environment.urlForService()
		client = .init(baseURL: baseURL, environment: environment)
	}

	// MARK: - Setup

	func stripeConfiguration() async throws(NetworkError) -> StripeConfiguration {
		do {
			let request = Request<StripeConfigurationResponseBody>(
				path: "/payments/publishable-key",
				method: .get
			)

			let response = try await client.send(request) { [apiKey] request in
				request.setAPIKey(apiKey)
			}
			return try StripeConfiguration.parse(response.value.data)
		} catch let error as NetworkError.Client {
			logCommonNetworkError(error, name: Self.serviceName)
			throw error.externalError
		} catch {
			logCommonNetworkError(error, name: Self.serviceName)
			throw NetworkError.unknown
		}
	}

	// MARK: - Payment

	func initiate(signedOffer: String) async throws(NetworkError) -> PaymentContext {
		do {
			let request = Request<PaymentInitiationResponeBody>(
				path: "/payments/initiate",
				method: .post,
				body: PaymentInitiationRequestBody(
					signedOffer: signedOffer
				)
			)

			let response = try await client.send(request) { [apiKey] request in
				request.setAPIKey(apiKey)
			}
			return try PaymentContext.parse(response.value.data)
		} catch let error as NetworkError.Client {
			logCommonNetworkError(error, name: Self.serviceName)
			throw error.externalError
		} catch {
			logCommonNetworkError(error, name: Self.serviceName)
			throw NetworkError.unknown
		}
	}

	func authorizeSession(
		paymentId: String
	) async throws(NetworkError) -> ChargeAuthentication {
		do {
			let request = Request<ChargeAuthenticationSchema>(
				path: "/payments/authorize-session",
				method: .post,
				body: ChargeAuthenticationRequestBody(paymentId: paymentId)
			)

			let response = try await client.send(request) { [apiKey] request in
				request.setAPIKey(apiKey)
			}
			return try ChargeAuthentication.parse(response.value)
		} catch let error as NetworkError.Client {
			logCommonNetworkError(error, name: Self.serviceName)
			throw error.externalError
		} catch {
			logCommonNetworkError(error, name: Self.serviceName)
			throw NetworkError.unknown
		}
	}

	// MARK: - Summary

	func summary(paymentId: String) async throws(NetworkError) -> PaymentSummary? {
		do {
			let request = Request<PaymentSummaryResponseBody>(
				path: "/payments/\(paymentId)/summary",
				method: .get
			)

			let response = try await client.send(request) { [apiKey] request in
				request.setAPIKey(apiKey)
			}

			guard let data = response.value.data else {
				return nil
			}

			return try PaymentSummary.parse(data)
		} catch let error as NetworkError.Client {
			logCommonNetworkError(error, name: Self.serviceName)
			throw error.externalError
		} catch {
			logCommonNetworkError(error, name: Self.serviceName)
			throw NetworkError.unknown
		}
	}
}

extension ChargeSettlementService {
	struct ChargeAuthenticationRequestBody: Encodable {
		let paymentId: String
	}

	struct PaymentInitiationRequestBody: Encodable {
		let signedOffer: String
	}

	struct PaymentInitiationResponeBody: Decodable {
		let data: PaymentContextSchema
	}

	struct StripeConfigurationResponseBody: Decodable {
		let data: StripeConfigurationSchema
	}

	struct PaymentSummaryResponseBody: Decodable {
		let data: PaymentSummarySchema?
	}
}
