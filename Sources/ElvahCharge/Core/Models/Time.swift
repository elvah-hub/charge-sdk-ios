// Copyright © elvah. All rights reserved.

import Foundation

package struct Time: Hashable, Codable, Sendable {
	package let timeZone: TimeZone
	package let hour: Int
	package let minute: Int
	package let second: Int?

	private var calendar: Calendar {
		var calendar = Calendar.current
		calendar.timeZone = timeZone
		return calendar
	}

	package var date: Date? {
		calendar.date(from: DateComponents(hour: hour, minute: minute, second: second))
	}

	package var secondsOfDay: Int {
		hour * 3600 + minute * 60
	}

	package func differenceInMinutes(to time: Time) -> Int {
		(time.secondsOfDay - secondsOfDay) / 60
	}

	package init?(timeString: String, timeZone: TimeZone = .current) {
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

	package init?(date: Date, timeZone: TimeZone = .current) {
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

	package init(hour: Int, minute: Int, second: Int? = nil, timeZone: TimeZone = .current) {
		self.timeZone = timeZone
		self.hour = hour
		self.minute = minute
		self.second = second
	}
}

extension Time: Equatable {
	package static func == (lhs: Time, rhs: Time) -> Bool {
		return lhs.secondsOfDay == rhs.secondsOfDay
	}
}

extension Time: Comparable {
	package static func < (lhs: Time, rhs: Time) -> Bool {
		return lhs.secondsOfDay < rhs.secondsOfDay
	}

	package static func <= (lhs: Time, rhs: Time) -> Bool {
		return lhs.secondsOfDay <= rhs.secondsOfDay
	}

	package static func >= (lhs: Time, rhs: Time) -> Bool {
		return lhs.secondsOfDay >= rhs.secondsOfDay
	}

	package static func > (lhs: Time, rhs: Time) -> Bool {
		return lhs.secondsOfDay > rhs.secondsOfDay
	}
}

private extension Collection {
	subscript(nilFallback index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
}
