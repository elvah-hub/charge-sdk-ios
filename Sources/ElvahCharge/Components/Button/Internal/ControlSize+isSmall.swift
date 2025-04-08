// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension ControlSize {
	var isSmall: Bool {
		self == .small || self == .mini
	}
}
