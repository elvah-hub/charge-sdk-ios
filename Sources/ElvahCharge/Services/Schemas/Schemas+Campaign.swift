// Copyright © elvah. All rights reserved.

extension Campaign {
	static func parse(_ response: CampaignSchema) throws(NetworkError) -> Campaign {
		do {
			let deals = try response.deals.map { try Deal.parse($0) }
			let site = Site(
				id: response.id,
				location: Site.Location(
					latitude: response.location[1],
					longitude: response.location[0]
				),
				address: Site.Address(
					locality: response.address.locality,
					postalCode: response.address.postalCode,
					streetAddress: response.address.streetAddress
				),
				availability: .available,
				prevalentPowerType: PowerType(rawValue: response.prevalentPowerType) ?? .ac,
				openingHours: nil,
				operatorName: response.operatorName
			)
			return Campaign(site: site, deals: deals)
		} catch {
			throw NetworkError.cannotParseServerResponse
		}
	}
}

struct CampaignSchema: Decodable {
	var id: String
	var location: [Double]
	var operatorName: String
	var prevalentPowerType: String
	var address: Address
	var deals: [DealSchema]

	struct Address: Decodable {
		var locality: String?
		var postalCode: String?
		var streetAddress: [String]?
	}
}
