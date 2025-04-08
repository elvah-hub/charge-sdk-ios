// Copyright © elvah. All rights reserved.

import CoreLocation
import SwiftUI

/// A place with one or more charge points to charge an electric car at.
public struct Site: Codable, Hashable, Identifiable, Sendable {
	/// A unique identification of a site.
	public var id: String

	package var location: Location
	package var address: Address?
	package var availability: Availability
	package var prevalentPowerType: PowerType
	package var openingHours: OpeningHours?
	package var operatorName: String?

	package init(
		id: String,
		location: Location,
		address: Address?,
		availability: Availability,
		prevalentPowerType: PowerType,
		openingHours: OpeningHours?,
		operatorName: String?
	) {
		self.id = id
		self.location = location
		self.address = address
		self.availability = availability
		self.prevalentPowerType = prevalentPowerType
		self.openingHours = openingHours
		self.operatorName = operatorName
	}
}

package extension Site {
	enum Availability: String, Codable, Hashable, CaseIterable, Sendable {
		case available = "AVAILABLE"
		case malfunctioningStation = "MALFUNCTIONING_STATION"
		case malfunctioningOperator = "MALFUNCTIONING_OPERATOR"
		case nonfunctional = "NONFUNCTIONAL"
		case occupied = "OCCUPIED"
	}

	struct Location: Codable, Hashable, Sendable {
		public let latitude: Double
		public let longitude: Double

		package init(latitude: Double, longitude: Double) {
			self.latitude = latitude
			self.longitude = longitude
		}
	}

	struct Address: Codable, Hashable, Sendable {
		public let locality: String?
		public let postalCode: String?
		public let streetAddress: [String]?

		package init(
			locality: String? = nil,
			postalCode: String? = nil,
			streetAddress: [String]? = nil
		) {
			self.locality = locality
			self.postalCode = postalCode
			self.streetAddress = streetAddress
		}
	}

	struct OpeningHours: Codable, Hashable, Sendable {
		package let dataAvailable: Bool
		package let openPeriods: [OpenPeriod]

		package init(dataAvailable: Bool, openPeriods: [Site.OpeningHours.OpenPeriod]) {
			self.dataAvailable = dataAvailable
			self.openPeriods = openPeriods
		}

		package struct OpenPeriod: Codable, Hashable, Sendable {
			package let dayOfWeek: String
			package let opensAt: Time
			package let closesAt: Time

			package init(dayOfWeek: String, opensAt: Time, closesAt: Time) {
				self.dayOfWeek = dayOfWeek
				self.opensAt = opensAt
				self.closesAt = closesAt
			}
		}
	}
}

package extension Site {
	static var mock: Site {
		Site(
			id: "Mock ID",
			location: Location(latitude: 51.03125, longitude: 4.41047),
			address: Site.Address(
				locality: "Berlin",
				postalCode: "12683",
				streetAddress: ["Köpenicker Straße 145"]
			),
			availability: .available,
			prevalentPowerType: .dc,
			openingHours: OpeningHours(
				dataAvailable: true,
				openPeriods: [
					Site.OpeningHours.OpenPeriod(
						dayOfWeek: "MONDAY",
						opensAt: Time(hour: 08, minute: 00),
						closesAt: Time(hour: 22, minute: 0)
					),
				]
			),
			operatorName: "Lidl Köpenicker Straße"
		)
	}
}
