// Copyright © elvah. All rights reserved.

import SwiftUI

/// A type describing a charge point.
package struct ChargePointDetails: Identifiable, Hashable, Codable, Sendable {
	/// The identifier of the charge point.
	package var id: String { evseId }

	/// The identifier of the charge point.
	package var evseId: String

	/// The charge point's physical reference, if available.
	package var physicalReference: String?

	/// The maximum power of the charge point in kW.
	package var maxPowerInKw: Double

	/// The charge point's availability.
	package var availability: Availability

	/// The date at which the charge point's availability was last updated.
	package var availabilityUpdatedAt: Date

	/// The charge point's connectors.
	package var connectors: Set<ConnectorType>

	/// The charge point's speed.
	package var speed: Speed

	/// The charge point's power type.
	package var powerType: PowerType?

	package init(
		evseId: String,
		physicalReference: String? = nil,
		maxPowerInKw: Double,
		availability: Availability,
		availabilityUpdatedAt: Date,
		connectors: Set<ConnectorType>,
		speed: Speed,
		powerType: PowerType?
	) {
		self.evseId = evseId
		self.physicalReference = physicalReference
		self.maxPowerInKw = maxPowerInKw
		self.availability = availability
		self.availabilityUpdatedAt = availabilityUpdatedAt
		self.connectors = connectors
		self.speed = speed
		self.powerType = powerType
	}
}

package extension ChargePointDetails {
	/// The chargepoint's speed.
	enum Speed: String, Hashable, Codable, Sendable {
		case unknown = "UNKNOWN"
		case slow = "SLOW"
		case medium = "MEDIUM"
		case fast = "FAST"
		case hyper = "HYPER"

		private var comparisonValue: Int {
			switch self {
			case .unknown:
				return 0
			case .slow:
				return 1
			case .medium:
				return 2
			case .fast:
				return 3
			case .hyper:
				return 4
			}
		}

		public static func < (lhs: Speed, rhs: Speed) -> Bool {
			lhs.comparisonValue < rhs.comparisonValue
		}

		public static func <= (lhs: Speed, rhs: Speed) -> Bool {
			lhs.comparisonValue <= rhs.comparisonValue
		}

		public static func >= (lhs: Speed, rhs: Speed) -> Bool {
			lhs.comparisonValue >= rhs.comparisonValue
		}

		public static func > (lhs: Speed, rhs: Speed) -> Bool {
			lhs.comparisonValue > rhs.comparisonValue
		}
	}

	/// The charge point's availability.
	enum Availability: String, Hashable, Codable, Sendable {
		case available
		case unavailable
		case outOfService
	}
}

// MARK: - Helpers

package extension ChargePointDetails {
	var isAvailable: Bool {
		availability == .available
	}

	var isUnavailable: Bool {
		availability != .available
	}

	@available(iOS 16.0, *) var maxPowerInKWFormatted: String {
		return maxPowerInKw.formatted(.number.precision(.fractionLength(0))) + " kW"
	}

	var evseIdSuffix: String {
		String(evseId.suffix(4))
	}

	/// The maximum power of the charge point in kW, formatted to be used in a user-facing string.
	var maxPowerInKwFormatted: String {
		"\(Int(maxPowerInKw))"
	}

	/// Returns a flag determining if the chargePoint's availability is set to `unavailable`.
	var isOccupied: Bool {
		availability == .unavailable
	}

	/// Returns a flag determining if the chargePoint's availability is set to `outOfService`.
	var isOutOfService: Bool {
		availability == .outOfService
	}

	var availabilityForegroundColor: Color {
		if isOccupied {
			return .yellow
		}

		if isOutOfService {
			return .red
		}

		return .onSuccess
	}

	var availabilityBackgroundColor: Color {
		if isOccupied {
			return .yellow.opacity(0.1)
		}

		if isOutOfService {
			return .red.opacity(0.1)
		}

		return .success
	}
}

// MARK: - Assets

package extension ConnectorType {
	/// The asset belonging to the connector.
	var assetName: String {
		switch self {
		case .chademo:
			"connector.chademo.filled"
		case .combo:
			"connector.combo.filled"
		case .other:
			"connector.other.filled"
		case .type2:
			"connector.type2.filled"
		}
	}

	var asset: Image {
		Image(assetName, bundle: .core)
	}
}

// MARK: - Mock Data

package extension ChargePointDetails {
	static func mockLoading(evseId: String) -> ChargePointDetails {
		ChargePointDetails(
			evseId: evseId,
			physicalReference: nil,
			maxPowerInKw: 150,
			availability: .available,
			availabilityUpdatedAt: Date().addingTimeInterval(-100_000),
			connectors: [.chademo],
			speed: .hyper,
			powerType: .ac
		)
	}

	static let mockAvailable = ChargePointDetails(
		evseId: "DE*SIM*1234",
		physicalReference: nil,
		maxPowerInKw: 150,
		availability: .available,
		availabilityUpdatedAt: Date().addingTimeInterval(-100_000),
		connectors: [.chademo],
		speed: .hyper,
		powerType: .ac
	)

	static let mockUnavailable = ChargePointDetails(
		evseId: "DE*SIM*1235",
		physicalReference: nil,
		maxPowerInKw: 20,
		availability: .unavailable,
		availabilityUpdatedAt: Date().addingTimeInterval(-200_000),
		connectors: [.combo],
		speed: .hyper,
		powerType: .dc
	)

	static let mockOutOfService = ChargePointDetails(
		evseId: "DE*SIM*1236",
		physicalReference: nil,
		maxPowerInKw: 350,
		availability: .outOfService,
		availabilityUpdatedAt: Date().addingTimeInterval(-300_000),
		connectors: [.chademo],
		speed: .hyper,
		powerType: .dc
	)
}
