// Copyright © elvah. All rights reserved.

extension StripeConfiguration {
	static func parse(
		_ response: StripeConfigurationSchema
	) throws(NetworkError.Client) -> StripeConfiguration {
		StripeConfiguration(publishableKey: response.publishableKey)
	}
}

struct StripeConfigurationSchema: Decodable {
	var publishableKey: String
}
