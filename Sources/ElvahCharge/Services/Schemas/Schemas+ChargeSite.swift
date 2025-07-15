// Copyright © elvah. All rights reserved.

extension ChargeSite {
	static func parse(_ response: SiteOfferSchema) throws(NetworkError.Client) -> ChargeSite {
		do {
			let offers = try response.evses.map { try ChargeOffer.parse($0) }
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
