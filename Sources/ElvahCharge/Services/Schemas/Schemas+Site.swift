// Copyright © elvah. All rights reserved.

import Foundation
import CoreLocation

extension Site {
	static func parse(_ response: SiteOfferSchema) throws(NetworkError.Client) -> Site {
		Site(
			id: response.id,
			location: CLLocationCoordinate2D(
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
	}
}
