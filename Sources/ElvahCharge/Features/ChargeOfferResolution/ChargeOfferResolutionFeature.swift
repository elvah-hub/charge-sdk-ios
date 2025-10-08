// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Core)
  import Core
#endif

@available(iOS 16.0, *)
struct ChargeOfferResolutionFeature: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var chargeSettlementProvider: ChargeSettlementProvider
  @EnvironmentObject private var discoveryProvider: DiscoveryProvider
  @TaskIdentifier private var signingId
  @Loadable<ChargeRequest> private var chargeRequest

  var chargeOffer: ChargeOffer

  var body: some View {
    Group {
      switch chargeRequest {
      case .absent,
           .loading:
        loadingContent
      case let .error(error):
        errorContent(error: error)
      case let .loaded(chargeRequest):
        ChargeEntryFeature(chargeRequest: chargeRequest)
      }
    }
    .task(id: signingId) {
      await signOffer()
    }
  }

  @ViewBuilder private var loadingContent: some View {
    NavigationStack {
      ActivityInfoComponent(state: .animating, title: nil, message: nil)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            CloseButton()
          }
        }
    }
  }

  @ViewBuilder private func errorContent(error: any Error) -> some View {
    NavigationStack {
      ErrorView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            CloseButton()
          }
        }
    }
  }

  // MARK: - Actions

  private func signOffer() async {
    await $chargeRequest.load {
      let signedOffer = try await discoveryProvider.signOffer(chargeOffer)
      let context = try await chargeSettlementProvider.initiate(with: signedOffer.token)
      try Task.checkCancellation()

      return ChargeRequest(
        site: chargeOffer.site,
        signedOffer: signedOffer,
        paymentContext: context,
      )
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  ChargeOfferResolutionFeature(chargeOffer: .mockAvailable)
    .withFontRegistration()
    .withMockEnvironmentObjects()
    .preferredColorScheme(.dark)
}
