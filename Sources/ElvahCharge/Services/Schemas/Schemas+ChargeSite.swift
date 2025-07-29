// Copyright © elvah. All rights reserved.

extension ChargeSite {
	static func parse(_ response: SiteOfferSchema) throws(NetworkError.Client) -> ChargeSite {
		do {
			let site = try Site.parse(response)
			let offers = try response.evses.map { try ChargeOffer.parse($0, in: site) }
			return ChargeSite(site: site, offers: offers)
		} catch {
			throw .parsing(.field("site"))
		}
	}
}

struct SiteOfferSchema: Decodable {
	var id: String
	var location: [Double]
	var operatorName: String
	var prevalentPowerType: String
	var address: AddressSchema
	var evses: [ChargeOfferSchema]

	struct AddressSchema: Decodable {
		var locality: String?
		var postalCode: String?
		var streetAddress: [String]?
	}
}
