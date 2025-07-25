// Copyright © elvah. All rights reserved.

import Foundation
import Playgrounds

/// A time representation with timezone, independent of date.
public struct Time: Hashable, Codable, Sendable {
	/// The timezone for this time.
	public var timeZone: TimeZone

	/// The hour component (0-23).
	public var hour: Int

	/// The minute component (0-59).
	///
	public var minute: Int

	/// The second component (0-59), if specified.
	public var second: Int?

	/// The current calendar.
	private var calendar: Calendar {
		var calendar = Calendar.current
		calendar.timeZone = timeZone
		return calendar
	}

	/// Creates a Time from a string in "HH:MM" or "HH:MM:SS" format.
	public init?(timeString: String, timeZone: TimeZone = .current) {
		let timeComponents = timeString
			.components(separatedBy: ":")
			.compactMap { Int($0) }

		guard let hour = timeComponents[nilFallback: 0],
					let minute = timeComponents[nilFallback: 1] else {
			return nil
		}

		guard hour >= 0 && hour <= 23 else { return nil }
		guard minute >= 0 && minute <= 59 else { return nil }

		self.timeZone = timeZone
		self.hour = hour
		self.minute = minute

		if let second = timeComponents[nilFallback: 2] {
			guard second >= 0 && second <= 59 else { return nil }
			self.second = second
		}
	}

	/// Creates a Time from a Date, extracting the time components in the specified timezone.
	public init?(date: Date, timeZone: TimeZone = .current) {
		var calendar = Calendar.current
		calendar.timeZone = timeZone

		let components = calendar.dateComponents([.hour, .minute, .second], from: date)

		guard let hour = components.hour, let minute = components.minute else {
			return nil
		}

		self.timeZone = timeZone
		self.hour = hour
		self.minute = minute
		second = components.second
	}

	/// Creates a Time with the specified hour, minute, and optional second.
	public init?(hour: Int, minute: Int, second: Int? = nil, timeZone: TimeZone = .current) {
		guard hour >= 0 && hour <= 23 else { return nil }
		guard minute >= 0 && minute <= 59 else { return nil }
		if let second = second {
			guard second >= 0 && second <= 59 else { return nil }
		}

		self.timeZone = timeZone
		self.hour = hour
		self.minute = minute
		self.second = second
	}

	public static let zero = Time(hour: 0, minute: 0)!

	/// Returns a `Date` object for today at this time, or nil if invalid.
	public var dateForToday: Date? {
		calendar.date(from: DateComponents(hour: hour, minute: minute, second: second))
	}

	/// The total seconds elapsed since midnight.
	public var secondsOfDay: Int {
		hour * 3600 + minute * 60 + (second ?? 0)
	}

	/// Returns the difference in minutes between this time and another time.
	public func differenceInMinutes(to time: Time) -> Int {
		(time.secondsOfDay - secondsOfDay) / 60
	}

	/// Returns a localized time string formatted for the timezone.
	public var localizedTimeString: String {
		if let date = dateForToday {
			// Start from the default date+time style
			var style = Date.FormatStyle.dateTime

			// Override the timezone to use when formatting
			style.timeZone = timeZone

			// Then apply your custom hour/minute digits (and omit AM/PM)
			style = style.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)

			return date.formatted(style)
		}
		
		return String(format: "%02d:%02d", hour, minute)
	}
}

extension Time: Equatable {
	public static func == (lhs: Time, rhs: Time) -> Bool {
		return lhs.secondsOfDay == rhs.secondsOfDay
	}
}

extension Time: Comparable {
	public static func < (lhs: Time, rhs: Time) -> Bool {
		return lhs.secondsOfDay < rhs.secondsOfDay
	}

	public static func <= (lhs: Time, rhs: Time) -> Bool {
		return lhs.secondsOfDay <= rhs.secondsOfDay
	}

	public static func >= (lhs: Time, rhs: Time) -> Bool {
		return lhs.secondsOfDay >= rhs.secondsOfDay
	}

	public static func > (lhs: Time, rhs: Time) -> Bool {
		return lhs.secondsOfDay > rhs.secondsOfDay
	}
}

private extension Collection {
	subscript(nilFallback index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
}
