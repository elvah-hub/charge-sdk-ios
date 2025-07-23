// Copyright elvah. All rights reserved.

import ElvahCharge
import MapKit
import SwiftUI

struct SimpleChargeBannerDemo: View {
  @ChargeBannerSource private var chargeBannerSource

  var body: some View {
    DemoContent {
      Button("Show Deals Nearby") {
        chargeBannerSource = .remote(in: .mock)
      }
      if let $chargeBannerSource {
        ChargeBanner(source: $chargeBannerSource)
          .padding(.horizontal, 15)
      }
    }
    .navigationTitle("Campaign Banner")
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: chargeBannerSource)
  }
}

#Preview {
  SimpleChargeBannerDemo()
    .preferredColorScheme(.dark)
}