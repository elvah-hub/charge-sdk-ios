// Copyright © elvah. All rights reserved.

import Combine
import SwiftUI

/// An instance of charging an electric car at a charge point.
public struct ChargeSession: Codable, Hashable, Sendable {
	package var evseId: String
	package var status: Status?
	package var consumption: KilowattHours
	package var duration: TimeInterval

	package init(
		evseId: String,
		status: Status? = nil,
		consumption: KilowattHours,
		duration: TimeInterval
	) {
		self.evseId = evseId
		self.status = status
		self.consumption = consumption
		self.duration = duration
	}

	package enum Status: String, Codable, Hashable, Sendable {
		case startRequested = "START_REQUESTED"
		case startRejected = "START_REJECTED"
		case started = "STARTED"
		case charging = "CHARGING"
		case stopRequested = "STOP_REQUESTED"
		case stopRejected = "STOP_REJECTED"
		case stopped = "STOPPED"
	}

	public enum CodingKeys: String, CodingKey {
		case evseId
		case status = "directChargeSessionStatus"
		case consumption
		case duration
	}
}

// MARK: - Mock Data

package extension ChargeSession {
	static func mock(
		status: ChargeSession.Status,
		evseId: String = ChargePoint.mockAvailable.details.evseId
	) -> ChargeSession {
		.init(
			evseId: evseId,
			status: status,
			consumption: 120,
			duration: 100
		)
	}
}

// MARK: - Helpers

package extension ChargeSession {
	var formattedConsumedKWh: String? {
		consumption.value.formatted(.number.precision(.fractionLength(2)))
	}

	var hasConsumption: Bool {
		consumption.value > 0
	}
}
