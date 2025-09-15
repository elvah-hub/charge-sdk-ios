// Copyright © elvah. All rights reserved.

import SwiftUI

extension ClosedRange<Date> {
	var textRepresentation: Text {
		let start = Text(lowerBound, format: .dateTime.hour().minute())
		let end = Text(upperBound, format: .dateTime.hour().minute())
		return Text("\(start) → \(end)", bundle: .elvahCharge)
	}

	var accessibilityTextRepresentation: Text {
		let start = Text(lowerBound, format: .dateTime.hour(.conversationalDefaultDigits(amPM: .wide)).minute())
		let end = Text(upperBound, format: .dateTime.hour(.conversationalDefaultDigits(amPM: .wide)).minute())
		return Text("From \(start) to \(end)", bundle: .elvahCharge)
	}
}
