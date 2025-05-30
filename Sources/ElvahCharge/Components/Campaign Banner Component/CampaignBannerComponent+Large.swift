// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension CampaignBannerComponent {
	struct LargeContent: View {
		@Environment(\.dynamicTypeSize) private var dynamicTypeSize

		var source: CampaignSource.Binding
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
					case let .campaign(campaign):
						campaignContent(campaign: campaign)
					case let .chargeSession(session):
						chargeSessionContent(session: session)
					}
				}
			}
			.padding(16)
			.typography(.title(size: .small), weight: .bold)
			.foregroundStyle(.primaryContent)
			.background(.container)
			.transformEffect(.identity)
		}

		@ViewBuilder private func campaignContent(campaign: Campaign) -> some View {
			TimelineView(.periodic(from: .now, by: 1)) { _ in
				if let deal = campaign.earliestEndingDeal {
					let price = deal.pricePerKWh.formatted()
					let priceLabel = Text("\(price)/kWh", bundle: .elvahCharge).foregroundColor(.brand)
					VStack(spacing: 24) {
						let siteName = campaign.site.operatorName ?? String(localized: "Site")
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
					.animation(.default, value: deal)
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
					Text("Failed to load charge session details", bundle: .elvahCharge)
						.multilineTextAlignment(.center)
						.lineSpacing(5)
					openChargePresentationButton
				} else {
					Text("Failed to load deal", bundle: .elvahCharge)
						.multilineTextAlignment(.center)
						.lineSpacing(5)
						.frame(maxWidth: .infinity)
				}
			}
		}

		@ViewBuilder private func chargeSessionContent(session: ChargeSession) -> some View {
			VStack(spacing: 24) {
				Text("You are already charging", bundle: .elvahCharge)
					.multilineTextAlignment(.center)
					.lineSpacing(5)
				openChargePresentationButton
			}
		}

		@ViewBuilder private var openChargePresentationButton: some View {
			ViewThatFits(in: .horizontal) {
				Button("Manage Charge Session", bundle: .elvahCharge, action: primaryAction)
				Button("Manage", bundle: .elvahCharge, action: primaryAction)
			}
			.buttonStyle(.primary)
		}
	}
}
