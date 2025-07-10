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
					case let .chargeSite(chargeSite):
						campaignContent(chargeSite: chargeSite)
					case .chargeSession:
						chargeSessionContent
					}
				}
			}
			.padding(16)
			.typography(.title(size: .small), weight: .bold)
			.foregroundStyle(.primaryContent)
			.background(.container)
			.transformEffect(.identity)
		}

		@ViewBuilder private func campaignContent(chargeSite: ChargeSite) -> some View {
			TimelineView(.periodic(from: .now, by: 1)) { _ in
				if let offer = chargeSite.earliestEndingChargeOffer {
					let price = offer.price.pricePerKWh.formatted()
					let priceLabel = Text("\(price)/kWh", bundle: .elvahCharge).foregroundColor(.brand)
					VStack(spacing: 24) {
						let siteName = chargeSite.operatorName ?? String(localized: "Site")
						Text("Charge at \(siteName) from \(priceLabel)", bundle: .elvahCharge)
							.fixedSize(horizontal: false, vertical: true)
							.contentTransition(.numericText())
						ViewThatFits(in: .horizontal) {
							Button("Discover the Offer", bundle: .elvahCharge, action: primaryAction)
							Button("Discover", bundle: .elvahCharge, action: primaryAction)
						}
						.buttonStyle(.primary)
					}
					.multilineTextAlignment(.center)
					.lineSpacing(dynamicTypeSize.isAccessibilitySize ? 2 : 5)
					.animation(.default, value: offer)
				} else {
					Text("This offer has expired, but more deals are coming!", bundle: .elvahCharge)
						.fixedSize(horizontal: false, vertical: true)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
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
					expiredContent
				} else {
					Text("Found no deal", bundle: .elvahCharge)
						.fixedSize(horizontal: false, vertical: true)
				}
			}
			.multilineTextAlignment(.center)
			.lineSpacing(5)
			.frame(maxWidth: .infinity)
		}

		@ViewBuilder private var expiredContent: some View {
			Text("This offer has expired, but more deals are coming!", bundle: .elvahCharge)
				.fixedSize(horizontal: false, vertical: true)
		}

		@ViewBuilder private func errorContent(error: any Error) -> some View {
			VStack(spacing: 24) {
				if source.chargeSession.isError {
					chargeSessionContent
				} else {
					Text("Failed to load deal", bundle: .elvahCharge)
						.multilineTextAlignment(.center)
						.lineSpacing(5)
						.frame(maxWidth: .infinity)
				}
			}
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
