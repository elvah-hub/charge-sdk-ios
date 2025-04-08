// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package struct MinimizeButton: View {
	var action: () -> Void

	package init(action: @escaping () -> Void) {
		self.action = action
	}

	package var body: some View {
		Button {
			action()
		} label: {
			Image(.expandMore)
				.resizable()
				.aspectRatio(contentMode: .fit)
				.frame(width: 25, height: 25)
				.foregroundStyle(.primaryContent)
		}
		.buttonStyle(.plain)
	}
}
