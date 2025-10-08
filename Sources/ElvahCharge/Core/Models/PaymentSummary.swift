// Copyright © elvah. All rights reserved.

import Foundation

package struct PaymentSummary: Codable, Hashable, Sendable {
  package var consumedKWh: KilowattHours
  package var sessionStartedAt: Date
  package var sessionEndedAt: Date
  package var totalCost: Currency

  package init(
    consumedKWh: KilowattHours,
    sessionStartedAt: Date,
    sessionEndedAt: Date,
    totalCost: Currency,
  ) {
    self.consumedKWh = consumedKWh
    self.sessionStartedAt = sessionStartedAt
    self.sessionEndedAt = sessionEndedAt
    self.totalCost = totalCost
  }
}

package extension PaymentSummary {
  static var mock: PaymentSummary {
    PaymentSummary(
      consumedKWh: 120,
      sessionStartedAt: Date().addingTimeInterval(-1000),
      sessionEndedAt: Date().addingTimeInterval(-50),
      totalCost: 42.0,
    )
  }
}
