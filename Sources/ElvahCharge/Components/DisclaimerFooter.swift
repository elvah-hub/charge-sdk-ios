// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct DisclaimerFooter: View {
  var body: some View {
    HStack(spacing: .size(.S)) {
      Text("Powered by", bundle: .elvahCharge)
        .foregroundStyle(.secondaryContent)
        .typography(.copy(size: .small))
      HStack(spacing: .size(.XS)) {
        Image(.diamond)
          .foregroundStyle(.brand)
        Image(.elvahTextLogo)
          .foregroundStyle(.primaryContent)
      }
    }
    .dynamicTypeSize(...(.xxLarge))
  }
}

@available(iOS 16.0, *)
#Preview {
  ZStack {
    Color.canvas.ignoresSafeArea()
    DisclaimerFooter()
  }
  .withFontRegistration()
}
