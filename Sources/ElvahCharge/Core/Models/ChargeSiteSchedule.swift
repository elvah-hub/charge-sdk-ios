// Copyright © elvah. All rights reserved.

import CoreLocation
import SwiftUI

/// A pricing schedule for a single charge site.
///
/// Combines the site details with its current and upcoming price windows
/// so you can present live pricing in the UI (for example with
/// ``LivePricingView``).
///
/// ## Getting a Schedule
///
/// ```swift
/// // From a ChargeSite instance
/// let schedule = try await chargeSite.pricingSchedule()
///
/// // Or using the static accessor
/// let schedule = try await ChargeSiteSchedule.schedule(for: chargeSite)
///
/// // Completion‑based variant
/// let observer = ChargeSiteSchedule.schedule(for: chargeSite) { result in
///   // handle Result<ChargeSiteSchedule, Elvah.Error>
/// }
/// ```
@dynamicMemberLookup
public struct ChargeSiteSchedule: Codable, Hashable, Identifiable, Sendable {
  public var id: String {
    chargeSite.id
  }

  /// The site this schedule belongs to.
  public var chargeSite: ChargeSite

  /// The resolved price timeline for the site.
  package var pricingSchedule: PricingSchedule

  /// Prepared data points for ``LivePricingView``.
  package var chartEntries: [PricingScheduleChartEntry]

  package init(chargeSite: ChargeSite, pricingSchedule: PricingSchedule) {
    self.chargeSite = chargeSite
    self.pricingSchedule = pricingSchedule
    self.chartEntries = pricingSchedule.chartEntries()
  }

  public subscript<V>(dynamicMember keyPath: KeyPath<PricingSchedule, V>) -> V {
    pricingSchedule[keyPath: keyPath]
  }

  public subscript<V>(dynamicMember keyPath: WritableKeyPath<PricingSchedule, V>) -> V {
    get { pricingSchedule[keyPath: keyPath] }
    set { pricingSchedule[keyPath: keyPath] = newValue }
  }

  package var dailyPricing: PricingSchedule.Days {
    get { pricingSchedule.dailyPricing }
    set { pricingSchedule.dailyPricing = newValue }
  }

  /// Maximum power in kilowatts for the prevalent power type found on the site, if available.
  package var prevalentPowerTypeMaxPowerInKw: Double? {
    chargeSite.offers.first { offer in
      offer.chargePoint.powerType == chargeSite.prevalentPowerType
    }?.chargePoint.maxPowerInKw
  }
}

// MARK: - Mock Data

package extension ChargeSiteSchedule {
  /// A representative schedule for previews and tests.
  static var mock: ChargeSiteSchedule {
    ChargeSiteSchedule(chargeSite: .mock, pricingSchedule: .mock)
  }
}
