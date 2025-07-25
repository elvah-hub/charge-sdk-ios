// Copyright © elvah. All rights reserved.

import Foundation

extension ChargeSession {
	static func parse(_ response: ChargeSessionSchema) throws(NetworkError.Client) -> ChargeSession {
		guard let status = ChargeSession.Status(rawValue: response.status) else {
			throw .parsing(.keyPath(in: response, keyPath: \.status))
		}

		return ChargeSession(
			evseId: response.evseId,
			status: status,
			consumption: KilowattHours(response.consumption ?? 0),
			duration: response.duration ?? 0
		)
	}
}

struct ChargeSessionCommandSchema: Decodable {
	var session: ChargeSessionSchema
}

struct ChargeSessionSchema: Decodable {
	var evseId: String
	var status: String
	var consumption: Double?
	var duration: Double?
}
