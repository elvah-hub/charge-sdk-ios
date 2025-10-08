// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct AdditionalCostsBottomSheet: View {
  @Environment(\.dismiss) private var dismiss

  var offer: ChargeOffer

  var body: some View {
    BottomSheetComponent(title: "Additional Costs") {
      AdditionalCostsBoxComponent(offer: offer)
    } footer: {
      Button("Understood", bundle: .elvahCharge) {
        dismiss()
      }
      .buttonStyle(.primary)
    }
  }
}

@available(iOS 16.0, *)
#Preview {
  Color.canvas.ignoresSafeArea()
    .sheet(isPresented: .constant(true)) {
      AdditionalCostsBottomSheet(offer: .mockAvailable)
    }
    .withFontRegistration()
    .preferredColorScheme(.dark)
}
