// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ButtonInternal {
	struct TextButtonLabelStyle: LabelStyle {
		@Environment(\.invertedButtonLabel) private var invertedButtonLabel

		func makeBody(configuration: Configuration) -> some View {
			HStack(alignment: .center, spacing: Size.XS.size) {
				if invertedButtonLabel {
					title(with: configuration)
					configuration.icon
				} else {
					configuration.icon
					title(with: configuration)
				}
			}
		}

		@ViewBuilder private func title(with configuration: Configuration) -> some View {
			configuration.title
				.padding(.bottom, Size.XXS.size + 2) // +2 for the line width that is added to the bottom
				.anchorPreference(
					key: BoundsPreferenceKey.self,
					value: .bounds
				) { $0 }
		}
	}
}
