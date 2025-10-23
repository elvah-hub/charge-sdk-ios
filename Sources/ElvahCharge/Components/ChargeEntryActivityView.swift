// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargeEntryActivityView: View {
  @Environment(\.navigationRoot) private var navigationRoot

  var state: ChargeEntryFeature.ViewState

  var body: some View {
    VStack(spacing: .size(.M)) {
      iconView
        .font(.themed(size: 40))
        .progressRing(progressMode)
        .progressRingTint(progressTint)
      messageView
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

  @ViewBuilder private var iconView: some View {
    if #available(iOS 17.0, *) {
      Image(iconResource)
        .contentTransition(.symbolEffect)
        .geometryGroup()
    } else {
      Image(iconResource)
    }
  }

  @ViewBuilder private var messageView: some View {
    switch state {
    case .loading:
      EmptyView()
    case .missingChargeContext:
      Text("No Charge Session", bundle: .elvahCharge)
        .typography(.copy(size: .large), weight: .bold)
        .fixedSize(horizontal: false, vertical: true)
        .transition(.opacity.combined(with: .offset(y: 25)))
    case .error:
      VStack(spacing: .size(.S)) {
        Text("An error occurred", bundle: .elvahCharge)
          .typography(.copy(size: .large), weight: .bold)
          .fixedSize(horizontal: false, vertical: true)
      }
      .multilineTextAlignment(.center)
      .transition(.opacity.combined(with: .offset(y: 25)))
    }
  }

  private var iconResource: ImageResource {
    switch state {
    case .loading:
      .bolt
    case .missingChargeContext,
         .error:
      .boltSlash
    }
  }

  private var progressMode: ProgressRing.Mode {
    switch state {
    case .loading:
      .indeterminate
    case .missingChargeContext:
      .completed
    case .error:
      .failed
    }
  }

  private var progressTint: Color? {
    switch state {
    case .loading:
      .secondary
    case .missingChargeContext:
      .primary
    case .error:
      .error
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
      Text(verbatim: "Error").tag(ChargeEntryFeature.ViewState.error)
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
