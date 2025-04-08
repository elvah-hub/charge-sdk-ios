// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension Site.Address {
	func formatted() -> String {
		var titleString = ""

		if let street = streetAddress?.first {
			titleString += street
		}

		if let postalCode = postalCode {
			titleString += ", "
			titleString += postalCode
		}

		if let city = locality {
			if postalCode != nil {
				titleString += " "
				titleString += city
			} else {
				titleString += ", "
				titleString += city
			}
		}

		return titleString
	}
}
