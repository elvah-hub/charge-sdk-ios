// Copyright © elvah. All rights reserved.

import Foundation

package extension Date {
  /// Full day range from midnight to midnight + 24h for consistent x-axis.
  var fullDayRange: ClosedRange<Date> {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: self)
    let end = calendar.date(byAdding: .hour, value: 24, to: start) ?? start
    return start ... end
  }
}
