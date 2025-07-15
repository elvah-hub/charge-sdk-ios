// Copyright © elvah. All rights reserved.

import Foundation

extension ChargeAuthentication {
	static func parse(
		_ response: ChargeAuthenticationSchema
	) throws(NetworkError.Client) -> ChargeAuthentication {
		ChargeAuthentication(
			token: response.data.chargeIdentityToken,
			expiryDate: nil
		)
	}
}

struct ChargeAuthenticationSchema: Decodable {
	let data: Data

	struct Data: Decodable {
		let chargeIdentityToken: String
	}
}
