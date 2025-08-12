// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ChargeBannerComponent {
	struct SmallContent: View {
		var source: ChargeBannerSource.Binding
		var viewState: LoadableState<ViewState>
		var action: () -> Void

		var body: some View {
			Button(action: action) {
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
						case let .chargeSession(session):
							chargeSessionContent(session: session)
						}
					}
				}
				.multilineTextAlignment(.leading)
				.lineSpacing(2)
				.padding(12)
				.frame(maxWidth: .infinity, alignment: .leading)
				.foregroundStyle(.primaryContent)
				.background(.container)
				.transformEffect(.identity)
			}
			.buttonStyle(.plain)
		}

		@ViewBuilder private func campaignContent(
			offer: ChargeOffer,
			chargeSite: ChargeSite
		) -> some View {
			TimelineView(.periodic(from: .now, by: 2)) { _ in
				HStack(spacing: 0) {
					ChargeOfferPricingView(offer: offer)
					Spacer()
					Image(.chevronRight)
				}
				.animation(.default, value: offer)
			}
		}

		@ViewBuilder private var absentContent: some View {
			HStack(spacing: 12) {
				if source.hasEnded {
					endedContent
				} else {
					Text("No offer found", bundle: .elvahCharge)
						.fixedSize(horizontal: false, vertical: true)
						.typography(.title(size: .small), weight: .bold)
				}
				Spacer()
			}
			.foregroundStyle(.primaryContent)
		}

		@ViewBuilder private var endedContent: some View {
			Text("This offer has ended, but more are coming!", bundle: .elvahCharge)
				.fixedSize(horizontal: false, vertical: true)
				.typography(.copy(size: .medium), weight: .bold)
		}

		@ViewBuilder private var loadingContent: some View {
			ProgressView()
				.progressViewStyle(.inlineActivity)
				.frame(maxWidth: .infinity)
		}

		@ViewBuilder private func errorContent(error: any Error) -> some View {
			HStack(spacing: 12) {
				if source.chargeSession.isError {
					Text("Failed to load charge session details", bundle: .elvahCharge)
					Spacer()
					Image(.chevronRight)
				} else {
					Text("Error loading offers", bundle: .elvahCharge)
					Spacer()
				}
			}
			.foregroundStyle(.primaryContent)
			.typography(.copy(size: .medium), weight: .bold)
		}

		@ViewBuilder private func chargeSessionContent(session: ChargeSession) -> some View {
			HStack(spacing: 12) {
				Text("Manage your current charge session", bundle: .elvahCharge)
					.foregroundStyle(.primaryContent)
				Spacer()
				Image(.chevronRight)
			}
			.typography(.copy(size: .medium), weight: .bold)
		}
	}
}
