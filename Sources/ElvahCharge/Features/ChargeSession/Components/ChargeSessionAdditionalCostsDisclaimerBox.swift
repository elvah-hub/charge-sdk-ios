// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargeSessionAdditionalCostsDisclaimerBox: View {
  var offer: ChargeOffer
  var onLearnMore: (ChargeOffer) -> Void

  var body: some View {
    Button {
      onLearnMore(offer)
    } label: {
      CustomBox {
        HStack(alignment: .top, spacing: .size(.XS)) {
          Image(.monetizationOn)
            .foregroundStyle(.primaryContent)
            .hiddenForLargeDynamicTypeSize()

          VStack(alignment: .leading, spacing: .size(.XXS)) {
            Text("Additional costs apply at this charge point.", bundle: .elvahCharge)
              .typography(.copy(size: .medium))
              .foregroundStyle(.secondaryContent)
              .fixedSize(horizontal: false, vertical: true)
              .dynamicTypeSize(...(.xxxLarge))
            Text("Learn more", bundle: .elvahCharge)
              .typography(.copy(size: .medium), weight: .bold)
              .underline()
              .fixedSize(horizontal: false, vertical: true)
              .dynamicTypeSize(...(.xxLarge))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .buttonStyle(.plain)
  }
}

@available(iOS 17.0, *)
#Preview {
  ChargeSessionAdditionalCostsDisclaimerBox(offer: .mockAvailable) { _ in }
    .padding()
    .preferredColorScheme(.dark)
    .withFontRegistration()
}
