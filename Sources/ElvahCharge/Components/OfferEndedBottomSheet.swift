// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct OfferEndedBottomSheet: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    BottomSheetComponent(title: title) {
      Text("This offer has ended, but more are coming!", bundle: .elvahCharge)
        .fixedSize(horizontal: false, vertical: true)
    } footer: {
      Button("Understood", bundle: .elvahCharge) {
        dismiss()
      }
      .buttonStyle(.primary)
    }
  }

  private var title: LocalizedStringKey {
    "Ended"
  }
}

@available(iOS 16.0, *)
#Preview {
  Color.canvas.ignoresSafeArea()
    .sheet(isPresented: .constant(true)) {
      OfferEndedBottomSheet()
    }
    .withFontRegistration()
    .preferredColorScheme(.dark)
}
