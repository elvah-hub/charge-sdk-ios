// Copyright © elvah. All rights reserved.

import ElvahCharge
import SwiftUI

@main
struct ExampleApp: App {
	init() {
		// Initialize the elvah Charge SDK as soon as possible in your app's lifecycle.
		// This initializer is a good place to do this, but you can also use an `AppDelegate`.
		Elvah
			.initialize(
				with: Elvah.Configuration(
					apiKey: "YOUR_API_KEY",
					theme: .default,
					store: .standard
				)
			)
	}

	var body: some Scene {
		WindowGroup {
			Root()
		}
	}
}
