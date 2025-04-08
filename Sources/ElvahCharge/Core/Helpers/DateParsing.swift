// Copyright © elvah. All rights reserved.

import Foundation

package extension Date {
	static func from(iso8601: String?) -> Date? {
		guard let iso8601 else {
			return nil
		}

		if let date = iso8601Formatter.date(from: iso8601) {
			return date
		}

		if let dateMS = iso8601FormatterWithFractionalSeconds.date(from: iso8601) {
			return dateMS
		}

		return nil
	}

	nonisolated(unsafe) static let iso8601FormatterWithFractionalSeconds: ISO8601DateFormatter = {
		let formatter = ISO8601DateFormatter()
		formatter.timeZone = .current
		formatter.formatOptions = [
			.withInternetDateTime,
			.withDashSeparatorInDate,
			.withColonSeparatorInTime,
			.withTimeZone,
			.withFractionalSeconds,
		]

		return formatter
	}()

	nonisolated(unsafe) static let iso8601Formatter: ISO8601DateFormatter = {
		let formatter = ISO8601DateFormatter()
		formatter.timeZone = .current
		formatter.formatOptions = [
			.withInternetDateTime,
			.withDashSeparatorInDate,
			.withColonSeparatorInTime,
			.withTimeZone,
		]

		return formatter
	}()

	nonisolated(unsafe) static let iso8601UTCFormatterWithFractionalSeconds: ISO8601DateFormatter = {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [
			.withInternetDateTime,
			.withDashSeparatorInDate,
			.withColonSeparatorInTime,
			.withFractionalSeconds,
		]

		return formatter
	}()

	nonisolated(unsafe) static let iso8601UTCFormatter: ISO8601DateFormatter = {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [
			.withInternetDateTime,
			.withDashSeparatorInDate,
			.withColonSeparatorInTime,
		]

		return formatter
	}()
}
