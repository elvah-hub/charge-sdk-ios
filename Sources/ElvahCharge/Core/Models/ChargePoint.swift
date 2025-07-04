// Copyright © elvah. All rights reserved.

import SwiftUI

/// A type describing a charge point.
public struct ChargePoint: Identifiable, Hashable, Codable, Sendable {
	/// The identifier of the charge point.
	public var id: String { evseId }

	/// The identifier of the charge point.
	public var evseId: String

	/// The charge point's physical reference, if available.
	public var physicalReference: String?

	/// The maximum power of the charge point in kW.
	public var maxPowerInKw: Double

	/// The charge point's availability.
	public var availability: Availability

	/// The date at which the charge point's availability was last updated.
	public var availabilityUpdatedAt: Date

	/// The charge point's connectors.
	public var connectors: Set<ConnectorType>

	/// The charge point's speed.
	public var speed: Speed

	/// The charge point's power type.
	public var powerType: PowerType?

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

public extension ChargePoint {
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

public extension ChargePoint {
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

package extension ChargePoint {
	static func mockLoading(evseId: String) -> ChargePoint {
		ChargePoint(
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

	static let mockAvailable = ChargePoint(
		evseId: "DE*SIM*1234",
		physicalReference: nil,
		maxPowerInKw: 150,
		availability: .available,
		availabilityUpdatedAt: Date().addingTimeInterval(-100_000),
		connectors: [.chademo],
		speed: .hyper,
		powerType: .ac
	)

	static let mockUnavailable = ChargePoint(
		evseId: "DE*SIM*1235",
		physicalReference: nil,
		maxPowerInKw: 20,
		availability: .unavailable,
		availabilityUpdatedAt: Date().addingTimeInterval(-200_000),
		connectors: [.combo],
		speed: .hyper,
		powerType: .dc
	)

	static let mockOutOfService = ChargePoint(
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
