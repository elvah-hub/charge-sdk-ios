// Copyright © elvah. All rights reserved.

import Foundation

package struct ServerErrorResponse: Error, Equatable, CustomDebugStringConvertible {
	package let httpStatusCode: Int
	package let title: String
	package let message: String?
	package let code: String?

	package init(httpStatusCode: Int, title: String, message: String? = nil, code: String? = nil) {
		self.httpStatusCode = httpStatusCode
		self.title = title
		self.message = message
		self.code = code
	}

	package var debugDescription: String {
		var desc = "ServerErrorResponse - HTTP \(httpStatusCode): \(title)"
		if let code = code {
			desc += " (Code: \(code))"
		}
		if let message = message {
			desc += " - \(message)"
		}
		return desc
	}
}

extension ServerErrorResponse {
	static func parse(_ response: ServerErrorsSchema) throws -> ServerErrorResponse {
		guard let data = response.errors.first else {
			throw UnexpectedError()
		}

		return ServerErrorResponse(
			httpStatusCode: Int(data.status) ?? -1,
			title: data.title,
			message: data.detail,
			code: data.code
		)
	}
}

struct ServerErrorsSchema: Decodable {
	let errors: [ServerErrorsSchema.Error]

	struct Error: Decodable, Swift.Error, Hashable {
		let status: String
		let title: String
		let detail: String?
		let code: String?
	}
}
