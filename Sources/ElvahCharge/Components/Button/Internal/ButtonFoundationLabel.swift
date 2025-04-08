// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package struct ButtonFoundationLabel<Content: View>: View {
	private var title: Content
	private var icon: Image

	package init(title: Content, icon: Image) {
		self.title = title
		self.icon = icon
	}

	package var body: some View {
		Label {
			title
		} icon: {
			ButtonFoundationImage(icon)
		}
		.buttonVariant(.label)
	}
}
