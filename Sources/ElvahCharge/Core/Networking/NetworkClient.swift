// Copyright © elvah. All rights reserved.

import Foundation

#if canImport(Get)
	import Get
#endif

/// A small wrapper around Get's `APIClient` that adds custom error handling and some other
/// configuration options.
package final class NetworkClient: Sendable {
	private let name: String
	private let client: APIClient
	private let delegate: Delegate

	package init(name: String, baseURL: URL?, environment: BackendEnvironment) {
		self.name = name
		delegate = Delegate()
		client = APIClient(baseURL: baseURL) { [delegate] configuration in
			configuration.delegate = delegate
			if Elvah.isDebugMode {
				configuration.sessionDelegate = Elvah.debugSessionDelegate
			}
		}
	}

	@discardableResult package func send<T>(
		_ request: Request<T>,
		configure: (@Sendable (inout URLRequest) throws -> Void)? = nil
	) async throws(NetworkError.Client) -> Response<T> where T: Decodable, T: Sendable {
		do {
			return try await withErrorHandling {
				try await client.send(request, configure: configure)
			}
		} catch {
			logCommonNetworkError(error, name: name)
			throw error
		}
	}

	@discardableResult package func send(
		_ request: Request<Void>,
		configure: (@Sendable (inout URLRequest) throws -> Void)? = nil
	) async throws(NetworkError.Client) -> Response<Void> {
		do {
			return try await withErrorHandling {
				try await client.send(request, configure: configure)
			}
		} catch {
			logCommonNetworkError(error, name: name)
			throw error
		}
	}

	private func withErrorHandling<T>(
		in block: () async throws -> Response<T>
	) async throws(NetworkError.Client) -> Response<T> {
		do {
			return try await block()
		} catch let error as EncodingError {
			throw NetworkError.Client.encoding(error)
		} catch let error as DecodingError {
			throw NetworkError.Client.decoding(error)
		} catch let error as ServerErrorResponse {
			throw NetworkError.Client.serverErrorResponse(error)
		} catch let error as APIError {
			switch error {
			case let .unacceptableStatusCode(statusCode):
				throw NetworkError.Client.unacceptableStatusCode(httpStatusCode: statusCode)
			}
		} catch let error as NSError {
			switch error.code {
			case NSURLErrorCannotConnectToHost,
			     NSURLErrorCannotFindHost,
			     NSURLErrorNetworkConnectionLost,
			     NSURLErrorNotConnectedToInternet,
			     NSURLErrorTimedOut:
				throw NetworkError.Client.connection(.from(code: error.code))
			default:
				throw NetworkError.Client.unknown(underlying: error)
			}
		} catch {
			throw NetworkError.Client.unknown(underlying: error)
		}
	}
}

// MARK: - APIClientDelegate

private final class Delegate: APIClientDelegate, Sendable {
	func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws {
		request.url = request.url?.properlyEncoded()
	}

	func client(
		_ client: APIClient,
		shouldRetry task: URLSessionTask,
		error: any Error,
		attempts: Int
	) async throws -> Bool {
		guard case let .unacceptableStatusCode(statusCode) = error as? APIError,
		      statusCode == 401 else {
			return false
		}

		if attempts >= 3 {
			return false
		}

		try await AuthenticationProvider(client: client).refreshBearer()
		return true
	}

	package func client(
		_ client: APIClient,
		validateResponse response: HTTPURLResponse,
		data: Data,
		task: URLSessionTask
	) throws {
		guard (200 ..< 400).contains(response.statusCode) else {
			do {
				let serverError = try JSONDecoder().decode(ServerErrorsSchema.self, from: data)
				throw try ServerErrorResponse.parse(serverError)
			} catch let error as ServerErrorResponse {
				throw error // Rethrow
			} catch {
				throw APIError.unacceptableStatusCode(response.statusCode)
			}
		}
	}
}

// MARK: - Authentication

private struct AuthenticationProvider {
	var client: APIClient

	func refreshBearer() async throws {
		// Make Refresh call
		await BearerHolder.shared.setBearer("")
	}
}

// MARK: - Bearer Holder

actor BearerHolder: Sendable {
	static let shared = BearerHolder()
	var bearer: String?

	private init() {}

	func setBearer(_ bearer: String?) {
		self.bearer = bearer
	}
}

// MARK: - Helpers

package extension URLRequest {
	mutating func setBearerToken(_ token: String) {
		addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
	}

	mutating func setAPIKey(_ key: String) {
		addValue("\(key)", forHTTPHeaderField: "x-api-key")
	}
	mutating func setDistinctId(_ id: String) {
		addValue("\(id)", forHTTPHeaderField: "X-Distinct-Id")
	}
}

private extension URL {
	func replacedEncodedUrl() -> URL {
		guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
			return self
		}

		// Replace encoding (to fix evseIds that contain a "+")
		components.percentEncodedQuery = components
			.percentEncodedQuery?
			.replacingOccurrences(of: "+", with: "%2B")

		// Write the encoded url back to the request
		return components.url ?? self
	}
}

private struct EmptyResponseError: Error {
	var statusCode: Int
}
