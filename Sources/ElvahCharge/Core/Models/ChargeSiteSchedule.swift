// Copyright © elvah. All rights reserved.

import CoreLocation
import SwiftUI

@dynamicMemberLookup
public struct ChargeSiteSchedule: Codable, Hashable, Identifiable, Sendable {
	public var id: String {
		chargeSite.id
	}

	/// The underlying charge site.
	package var chargeSite: ChargeSite

	/// The underlying pricing schedule.
	package var pricingSchedule: PricingSchedule

	package var chartEntries: [PricingScheduleChartEntry]

	package init(chargeSite: ChargeSite, pricingSchedule: PricingSchedule) {
		self.chargeSite = chargeSite
		self.pricingSchedule = pricingSchedule
		self.chartEntries = pricingSchedule.chartEntries()
	}

	package subscript<V>(dynamicMember keyPath: KeyPath<PricingSchedule, V>) -> V {
		pricingSchedule[keyPath: keyPath]
	}

	package subscript<V>(dynamicMember keyPath: WritableKeyPath<PricingSchedule, V>) -> V {
		get { pricingSchedule[keyPath: keyPath] }
		set { pricingSchedule[keyPath: keyPath] = newValue }
	}

	package var dailyPricing: PricingSchedule.Days {
		get { pricingSchedule.dailyPricing }
		set { pricingSchedule.dailyPricing = newValue }
	}
}

// MARK: - Mock Data

package extension ChargeSiteSchedule {
	static var mock: ChargeSiteSchedule {
		ChargeSiteSchedule(chargeSite: .mock, pricingSchedule: .mock)
	}
}
