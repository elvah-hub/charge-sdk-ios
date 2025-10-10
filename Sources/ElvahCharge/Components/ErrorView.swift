// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ErrorView: View {
  var error: (any Error)?

  var body: some View {
    VStack(spacing: .size(.M)) {
      Image(.boltSlash)
        .foregroundStyle(.onError)
        .font(.themed(size: 40))
        .progressRing(.failed)
      VStack(spacing: .size(.XS)) {
        Text("An error occurred", bundle: .elvahCharge)
          .typography(.title(size: .medium), weight: .bold)
          .foregroundStyle(.primaryContent)
          .frame(maxWidth: .infinity)
          .fixedSize(horizontal: false, vertical: true)
        Text("An unexpected error occurred.", bundle: .elvahCharge)
          .dynamicTypeSize(...(.accessibility1))
          .typography(.copy(size: .medium))
          .foregroundStyle(.secondaryContent)
          .frame(maxWidth: .infinity)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity)
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  ErrorView()
    .preferredColorScheme(.dark)
}
