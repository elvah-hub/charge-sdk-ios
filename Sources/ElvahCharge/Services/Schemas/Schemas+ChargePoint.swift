// Copyright © elvah. All rights reserved.

import Foundation

extension ChargePoint {
	static func parse(_ response: ChargeOfferSchema) throws(NetworkError.Client) -> ChargePoint {
		var powerType: PowerType? {
			if let powerSpecification = response.powerSpecification {
				return PowerType(rawValue: powerSpecification.type)
			}
			return nil
		}

		return ChargePoint(
			evseId: response.evseId,
			physicalReference: nil,
			maxPowerInKw: response.powerSpecification?.maxPowerInKW ?? 0,
			availability: .available, // TODO: Missing
			availabilityUpdatedAt: Date.now, // TODO: Missing
			connectors: [], // TODO: Missing
			speed: .unknown, // TODO: Missing
			powerType: powerType
		)
	}
}
