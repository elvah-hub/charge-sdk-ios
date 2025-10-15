// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargeSessionSupportActionsBox: View {
  var onContactSupport: () -> Void
  var onStopCharging: () -> Void

  var body: some View {
    CustomBox {
      VStack(alignment: .leading, spacing: .size(.S)) {
        header
        actions
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: .size(.S)) {
      HStack(alignment: .top, spacing: .size(.S)) {
        Image(.agent)
          .foregroundStyle(.primaryContent)
          .hiddenForLargeDynamicTypeSize()
        Text("Need help?", bundle: .elvahCharge)
          .typography(.copy(size: .medium), weight: .bold)
          .foregroundStyle(.primaryContent)
          .fixedSize(horizontal: false, vertical: true)
      }
      Text("We're here if you face issues during charging.", bundle: .elvahCharge)
        .typography(.copy(size: .medium))
        .foregroundStyle(.secondaryContent)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .dynamicTypeSize(...(.xxxLarge))
  }

  private var actions: some View {
    HStack(alignment: .firstTextBaseline, spacing: .size(.M)) {
      Button(action: onContactSupport) {
        Text("Contact support", bundle: .elvahCharge)
          .typography(.copy(size: .medium), weight: .bold)
          .underline()
      }
      .buttonStyle(.plain)
      // TODO: Re-enable once behavior is properly specified
//      Button(action: onStopCharging) {
//        Text("Stop charging", bundle: .elvahCharge)
//          .typography(.copy(size: .medium), weight: .bold)
//          .underline()
//      }
//      .buttonStyle(.plain)
    }
    .foregroundStyle(.primaryContent)
    .dynamicTypeSize(...(.xxLarge))
  }
}

@available(iOS 17.0, *)
#Preview {
  ChargeSessionSupportActionsBox(
    onContactSupport: {},
    onStopCharging: {}
  )
  .padding()
  .preferredColorScheme(.dark)
  .withFontRegistration()
}
