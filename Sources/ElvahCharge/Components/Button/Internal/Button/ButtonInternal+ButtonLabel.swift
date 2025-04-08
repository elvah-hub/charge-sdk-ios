// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ButtonInternal {
	struct ButtonLabel: View {
		@Environment(\.redactionReasons) private var redactionReasons
		@Environment(\.controlSize) private var controlSize
		@Environment(\.isLoading) private var isLoading

		let configuration: ButtonStyleConfiguration
		@Binding var variant: ButtonVariant

		var body: some View {
			if redactionReasons.contains(.placeholder) {
				baseLabel.hidden()
			} else if isLoading {
				baseLabel.hidden()
					.overlay(ProgressView())
			} else {
				baseLabel
			}
		}

		@ViewBuilder private var baseLabel: some View {
			configuration.label.readButtonVariant(variant: $variant)
		}
	}
}
