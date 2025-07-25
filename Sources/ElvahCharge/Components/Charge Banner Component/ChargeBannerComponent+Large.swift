// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ChargeBannerComponent {
	struct LargeContent: View {
		@Environment(\.dynamicTypeSize) private var dynamicTypeSize

		var source: ChargeBannerSource.Binding
		var viewState: LoadableState<ViewState>
		var primaryAction: () -> Void
		var retryAction: () -> Void

		var body: some View {
			ZStack {
				switch viewState {
				case .absent:
					absentContent
				case .loading:
					loadingContent
				case let .error(error):
					errorContent(error: error)
				case let .loaded(loadedData):
					switch loadedData {
					case let .chargeOffer(offer, chargeSite):
						campaignContent(offer: offer, chargeSite: chargeSite)
					case .chargeSession:
						chargeSessionContent
					}
				}
			}
			.padding(16)
			.foregroundStyle(.primaryContent)
			.background(.container)
			.transformEffect(.identity)
		}

		@ViewBuilder private func campaignContent(
			offer: ChargeOffer,
			chargeSite: ChargeSite
		) -> some View {
			TimelineView(.periodic(from: .now, by: 1)) { _ in
				VStack(spacing: 16) {
					ChargeOfferPricingView(offer: offer)
					Button("Charge Now", icon: .bolt, bundle: .elvahCharge, action: primaryAction)
						.buttonStyle(.primary)
				}
				.animation(.default, value: offer)
			}
			.frame(maxWidth: .infinity)
		}

		@ViewBuilder private var loadingContent: some View {
			ProgressView()
				.progressViewStyle(.inlineActivity)
				.frame(maxWidth: .infinity)
		}

		@ViewBuilder private var absentContent: some View {
			Group {
				if source.hasEnded {
					endedContent
				} else {
					Text("No offer found", bundle: .elvahCharge)
						.fixedSize(horizontal: false, vertical: true)
						.typography(.title(size: .small), weight: .bold)
				}
			}
			.multilineTextAlignment(.center)
			.lineSpacing(5)
			.frame(maxWidth: .infinity)
		}

		@ViewBuilder private var endedContent: some View {
			Text("This offer has expired, but more are coming!", bundle: .elvahCharge)
				.typography(.title(size: .small), weight: .bold)
				.fixedSize(horizontal: false, vertical: true)
		}

		@ViewBuilder private func errorContent(error: any Error) -> some View {
			VStack(spacing: 24) {
				if source.chargeSession.isError {
					chargeSessionContent
				} else {
					Text("Failed to load offer", bundle: .elvahCharge)
						.multilineTextAlignment(.center)
						.lineSpacing(5)
						.frame(maxWidth: .infinity)
				}
			}
			.typography(.title(size: .small), weight: .bold)
		}

		@ViewBuilder private var chargeSessionContent: some View {
			Button(action: primaryAction) {
				HStack(spacing: 12) {
					Text("Manage your current charge session", bundle: .elvahCharge)
						.foregroundStyle(.primaryContent)
					Spacer()
					Image(.chevronRight)
				}
				.multilineTextAlignment(.leading)
			}
			.typography(.copy(size: .medium), weight: .bold)
		}
	}
}
