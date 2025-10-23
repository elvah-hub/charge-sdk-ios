// Copyright © elvah. All rights reserved.

import Foundation

private final class BundleLocationClass {}

extension Bundle {
  static let elvahCharge: Bundle = {
    #if SWIFT_PACKAGE
      .module
    #else
      let sdkBundle = Bundle(for: BundleLocationClass.self)

      guard
        let resourceBundleURL = sdkBundle.url(
          forResource: "ElvahCharge",
          withExtension: "bundle",
        )
      else {
        fatalError("ElvahCharge.bundle not found")
      }

      guard let resourceBundle = Bundle(url: resourceBundleURL) else {
        fatalError("Cannot access ElvahCharge.bundle")
      }

      return resourceBundle
    #endif
  }()
}
