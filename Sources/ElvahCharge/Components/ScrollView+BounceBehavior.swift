// Copyright © elvah. All rights reserved.

import SwiftUI

extension View {
	@ViewBuilder func scrollBounceBehaviorBasedOnSizeIfAvailable(
		axes: Axis.Set = [.vertical],
	) -> some View {
		if #available(iOS 16.4, *) {
			self.scrollBounceBehavior(.basedOnSize, axes: axes)
		} else {
			self
		}
	}
}
