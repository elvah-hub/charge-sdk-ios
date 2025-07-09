// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Core)
	import Core
#endif

@available(iOS 16.0, *)
struct ChargeOfferResolutionFeature: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject private var chargeSettlementProvider: ChargeSettlementProvider
	@TaskIdentifier private var signingId
	@Loadable<ChargeRequest> private var chargeRequest

	var chargeSite: ChargeSite
	var chargeOffer: ChargeOffer

	var body: some View {
		Group {
			switch chargeRequest {
			case .absent,
			     .loading:
				ActivityInfoComponent(state: .animating, title: nil, message: nil)
			case .error:
				// TODO: Generic error bottom sheet as fullscreen component
				Text("Error")
			case let .loaded(chargeRequest):
				ChargeEntryFeature(chargeRequest: chargeRequest)
			}
		}
		.task(id: signingId) {
			await signOffer()
		}
	}

	private func signOffer() async {
		await $chargeRequest.load {
			let signedOffer = SignedChargeOffer(offer: chargeOffer, signedOffer: "")
			let context = try await chargeSettlementProvider.initiate(
				signedOffer: signedOffer.signedOffer
			)
			return ChargeRequest(
				site: chargeSite.site,
				signedOffer: signedOffer,
				paymentContext: context
			)
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	ChargeOfferResolutionFeature(chargeSite: .mock, chargeOffer: .mockAvailable)
		.withFontRegistration()
		.withMockEnvironmentObjects()
		.preferredColorScheme(.dark)
}
