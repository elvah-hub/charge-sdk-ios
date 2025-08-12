// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ErrorView: View {
	var error: (any Error)?

	var body: some View {
		ActivityInfoComponent(
			state: .error,
			title: "An error occurred",
			message: "An unexpected error occurred."
		)
	}
}

@available(iOS 17.0, *)
#Preview {
	ErrorView()
}
