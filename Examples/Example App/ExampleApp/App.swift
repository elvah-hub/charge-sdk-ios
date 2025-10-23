// Copyright © elvah. All rights reserved.

import ElvahCharge
import SwiftUI

@main
struct ExampleApp: App {
  init() {
    // Initialize the elvah Charge SDK as soon as possible in your app's lifecycle.
    // This initializer is a good place to do this, but you can also use an `AppDelegate`.
    Elvah.initialize(with: .simulator)

    // Or: Initialize with a custom font family
    //		Elvah.initialize(
    //			with: .simulator(
    //				theme: .init(
    //					color: .default,
    //					typography: .init(font: .custom(family: "Avenir Next Condensed"))
    //				)
    //			)
    //		)
  }

  var body: some Scene {
    WindowGroup {
      Root()
    }
  }
}
