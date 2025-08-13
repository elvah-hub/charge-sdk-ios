// Copyright © elvah. All rights reserved.

import SwiftUI

@dynamicMemberLookup
package struct AuthenticatedChargeRequest: Hashable, Sendable, Identifiable {
	package var id: String {
		request.id
	}

	package var request: ChargeRequest
	package var authentication: ChargeAuthentication

	package init(_ request: ChargeRequest, authentication: ChargeAuthentication) {
		self.request = request
		self.authentication = authentication
	}

	package subscript<T>(dynamicMember keyPath: KeyPath<ChargeRequest, T>) -> T {
		request[keyPath: keyPath]
	}

	package subscript<T>(dynamicMember keyPath: WritableKeyPath<ChargeRequest, T>) -> T {
		get {
			request[keyPath: keyPath]
		} set {
			request[keyPath: keyPath] = newValue
		}
	}
}

package extension AuthenticatedChargeRequest {
	static var mock: AuthenticatedChargeRequest {
		AuthenticatedChargeRequest(.mock, authentication: .mock)
	}
}
