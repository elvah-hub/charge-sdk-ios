// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargeEntryActivityView: View {
  @Environment(\.navigationRoot) private var navigationRoot

  var state: ChargeEntryFeature.ViewState

  var body: some View {
    VStack(spacing: .size(.M)) {
      Group {
        if #available(iOS 17.0, *) {
          Image(state == .loading ? .bolt : .boltSlash)
            .contentTransition(.symbolEffect)
            .geometryGroup()
        } else {
          Image(state == .loading ? .bolt : .boltSlash)
        }
      }
      .font(.themed(size: 40))
      .progressRing(state == .loading ? .indeterminate : .completed)
      .progressRingTint(state == .loading ? .secondary : .primary)
      if state == .missingChargeContext {
        Text("No Charge Session", bundle: .elvahCharge)
          .typography(.copy(size: .large), weight: .bold)
          .fixedSize(horizontal: false, vertical: true)
          .transition(.opacity.combined(with: .offset(y: 25)))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.canvas)
    .scrollContentBackground(.hidden)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        CloseButton {
          navigationRoot.dismiss()
        }
      }
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  @Previewable @State var previewState: ChargeEntryFeature.ViewState = .loading

  VStack(spacing: 24) {
    ChargeEntryActivityView(state: previewState)
      .frame(height: 320)
    Picker(selection: $previewState) {
      Text(verbatim: "Loading").tag(ChargeEntryFeature.ViewState.loading)
      Text(verbatim: "Missing Charge Context").tag(ChargeEntryFeature.ViewState.missingChargeContext)
    } label: {
      Text(verbatim: "Charge Entry View State")
    }
    .pickerStyle(.segmented)
  }
  .padding()
  .preferredColorScheme(.dark)
  .withFontRegistration()
  .animation(.default, value: previewState)
}
