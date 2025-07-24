// Copyright © elvah. All rights reserved.

import Foundation

public struct Time: Hashable, Codable, Sendable {
	public let timeZone: TimeZone
	public let hour: Int
	public let minute: Int
	public let second: Int?

	private var calendar: Calendar {
		var calendar = Calendar.current
		calendar.timeZone = timeZone
		return calendar
	}

	public var date: Date? {
		calendar.date(from: DateComponents(hour: hour, minute: minute, second: second))
	}

	public var secondsOfDay: Int {
		hour * 3600 + minute * 60
	}

	public func differenceInMinutes(to time: Time) -> Int {
		(time.secondsOfDay - secondsOfDay) / 60
	}

	public var localizedTimeString: String {
		let formatter = DateFormatter()
		formatter.timeStyle = .short
		formatter.timeZone = timeZone
		if let date = date {
			return formatter.string(from: date)
		}
		return String(format: "%02d:%02d", hour, minute)
	}

	public init?(timeString: String, timeZone: TimeZone = .current) {
		let timeComponents = timeString
			.components(separatedBy: ":")
			.compactMap { Int($0) }

		guard let hour = timeComponents[nilFallback: 0],
		      let minute = timeComponents[nilFallback: 1] else {
			return nil
		}

		self.timeZone = timeZone
		self.hour = hour
		self.minute = minute
		second = timeComponents[nilFallback: 2]
	}

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

	public init(hour: Int, minute: Int, second: Int? = nil, timeZone: TimeZone = .current) {
		self.timeZone = timeZone
		self.hour = hour
		self.minute = minute
		self.second = second
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
