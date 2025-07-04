// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension CampaignBannerComponent {
	struct SmallContent: View {
		var source: CampaignSource.Binding
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
						case let .campaign(campaign):
							campaignContent(campaign: campaign)
						case let .chargeSession(session):
							chargeSessionContent(session: session)
						}
					}
				}
				.typography(.copy(size: .medium), weight: .bold)
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

		@ViewBuilder private func campaignContent(campaign: Campaign) -> some View {
			TimelineView(.periodic(from: .now, by: 2)) { _ in
				if let offer = campaign.chargeSite.earliestEndingOffer {
					let price = offer.price.pricePerKWh.formatted()
					let priceLabel = Text("\(price)/kWh", bundle: .elvahCharge).foregroundColor(.brand)
					HStack(spacing: 12) {
						let siteName = campaign.chargeSite.operatorName ?? String(localized: "Site")
						Text("Charge at \(siteName) from \(priceLabel)", bundle: .elvahCharge)
							.contentTransition(.numericText())
						Spacer()
						Image(.chevronRight)
					}
					.animation(.default, value: offer)
				} else {
					expiredContent
				}
			}
		}

		@ViewBuilder private var absentContent: some View {
			HStack(spacing: 12) {
				if source.hasEnded {
					expiredContent
				} else {
					Text("Found no deal", bundle: .elvahCharge)
						.fixedSize(horizontal: false, vertical: true)
				}
				Spacer()
			}
			.foregroundStyle(.primaryContent)
		}

		@ViewBuilder private var expiredContent: some View {
			Text("This offer has expired, but more deals are coming!", bundle: .elvahCharge)
				.fixedSize(horizontal: false, vertical: true)
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
					Text("Failed to load deal", bundle: .elvahCharge)
					Spacer()
				}
			}
			.foregroundStyle(.primaryContent)
		}

		@ViewBuilder private func chargeSessionContent(session: ChargeSession) -> some View {
			HStack(spacing: 12) {
				Text("Manage your current charge session", bundle: .elvahCharge)
					.foregroundStyle(.primaryContent)
				Spacer()
				Image(.chevronRight)
			}
		}
	}
}
