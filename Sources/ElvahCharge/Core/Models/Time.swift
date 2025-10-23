// Copyright © elvah. All rights reserved.

import Foundation

/// A time representation with timezone, independent of date.
public struct Time: Hashable, Codable, Sendable {
  /// The timezone for this time.
  public var timeZone: TimeZone

  /// The hour component (0-23).
  public var hour: Int

  /// The minute component (0-59).
  public var minute: Int

  /// The second component (0-59), if specified.
  public var second: Int?

  /// A calendar configured with this time's timezone.
  private var calendar: Calendar {
    var calendar = Calendar.current
    calendar.timeZone = timeZone
    return calendar
  }

  /// Creates a Time from a string in "HH:MM" or "HH:MM:SS" format.
  /// - Parameters:
  ///   - timeString: A string in "HH:MM" or "HH:MM:SS" format
  ///   - timeZone: The timezone for this time (defaults to current timezone)
  public init?(timeString: String, timeZone: TimeZone = .current) {
    let trimmedString = timeString.trimmingCharacters(in: .whitespacesAndNewlines)
    let timeComponents = trimmedString
      .components(separatedBy: ":")
      .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

    guard timeComponents.count >= 2,
          let hour = timeComponents[safe: 0],
          let minute = timeComponents[safe: 1] else {
      return nil
    }

    guard hour >= 0, hour <= 23 else {
      return nil
    }
    guard minute >= 0, minute <= 59 else {
      return nil
    }

    self.timeZone = timeZone
    self.hour = hour
    self.minute = minute

    if let second = timeComponents[safe: 2] {
      guard second >= 0, second <= 59 else {
        return nil
      }
      self.second = second
    } else {
      second = nil
    }
  }

  /// Creates a Time from a Date, extracting the time components in the specified timezone.
  /// - Parameters:
  ///   - date: The date to extract time from
  ///   - timeZone: The timezone for this time (defaults to current timezone)
  public init?(date: Date, timeZone: TimeZone = .current) {
    var calendar = Calendar.current
    calendar.timeZone = timeZone

    let components = calendar.dateComponents([.hour, .minute, .second], from: date)

    guard let hour = components.hour,
          let minute = components.minute,
          hour >= 0, hour <= 23,
          minute >= 0, minute <= 59 else {
      return nil
    }

    self.timeZone = timeZone
    self.hour = hour
    self.minute = minute

    if let second = components.second, second >= 0, second <= 59 {
      self.second = second
    } else {
      second = nil
    }
  }

  /// Creates a Time with the specified hour, minute, and optional second.
  /// - Parameters:
  ///   - hour: The hour component (0-23)
  ///   - minute: The minute component (0-59)
  ///   - second: The second component (0-59), optional
  ///   - timeZone: The timezone for this time (defaults to current timezone)
  public init?(hour: Int, minute: Int, second: Int? = nil, timeZone: TimeZone = .current) {
    guard hour >= 0, hour <= 23 else {
      return nil
    }
    guard minute >= 0, minute <= 59 else {
      return nil
    }
    if let second {
      guard second >= 0, second <= 59 else {
        return nil
      }
    }

    self.timeZone = timeZone
    self.hour = hour
    self.minute = minute
    self.second = second
  }

  /// A constant representing midnight (00:00).
  public static let zero = Time(hour: 0, minute: 0)!

  /// A constant representing noon (12:00).
  public static let noon = Time(hour: 12, minute: 0)!

  /// Returns a `Date` object for today at this time in the time's timezone.
  public var dateForToday: Date? {
    calendar.date(from: DateComponents(hour: hour, minute: minute, second: second))
  }

  /// Returns a `Date` object for the specified date at this time.
  /// - Parameter date: The date to combine with this time
  /// - Returns: A `Date` representing the specified date at this time, or nil if invalid
  public func date(on date: Date) -> Date? {
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
    var components = DateComponents()
    components.year = dateComponents.year
    components.month = dateComponents.month
    components.day = dateComponents.day
    components.hour = hour
    components.minute = minute
    components.second = second

    return calendar.date(from: components)
  }

  /// The total seconds elapsed since midnight.
  public var secondsOfDay: Int {
    hour * 3600 + minute * 60 + (second ?? 0)
  }

  /// Returns the difference in minutes between this time and another time.
  /// - Parameter time: The time to compare to
  /// - Returns: The difference in minutes (positive if the other time is later)
  public func differenceInMinutes(to time: Time) -> Int {
    (time.secondsOfDay - secondsOfDay) / 60
  }

  /// Returns the difference in seconds between this time and another time.
  /// - Parameter time: The time to compare to
  /// - Returns: The difference in seconds (positive if the other time is later)
  public func differenceInSeconds(to time: Time) -> Int {
    time.secondsOfDay - secondsOfDay
  }

  /// Returns a localized time string formatted for the timezone.
  public var localizedTimeString: String {
    if let date = dateForToday {
      var style = Date.FormatStyle.dateTime
      style.timeZone = timeZone
      style = style.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)

      if second != nil {
        style = style.second(.twoDigits)
      }

      return date.formatted(style)
    }

    if let second {
      return String(format: "%02d:%02d:%02d", hour, minute, second)
    } else {
      return String(format: "%02d:%02d", hour, minute)
    }
  }
}

extension Time: Comparable {
  public static func < (lhs: Time, rhs: Time) -> Bool {
    lhs.secondsOfDay < rhs.secondsOfDay
  }

  public static func <= (lhs: Time, rhs: Time) -> Bool {
    lhs.secondsOfDay <= rhs.secondsOfDay
  }

  public static func >= (lhs: Time, rhs: Time) -> Bool {
    lhs.secondsOfDay >= rhs.secondsOfDay
  }

  public static func > (lhs: Time, rhs: Time) -> Bool {
    lhs.secondsOfDay > rhs.secondsOfDay
  }
}

// MARK: - Custom String Convertible

extension Time: CustomStringConvertible {
  public var description: String {
    if let second {
      String(format: "%02d:%02d:%02d %@", hour, minute, second, timeZone.identifier)
    } else {
      String(format: "%02d:%02d %@", hour, minute, timeZone.identifier)
    }
  }
}

private extension Collection {
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
