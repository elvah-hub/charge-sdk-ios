// Copyright © elvah. All rights reserved.

import Defaults
import SwiftUI

@available(iOS 16.0, *)
extension CampaignBannerComponent {
	struct Header: View {
		@Default(.chargeSessionContext) private var chargeSessionContext
		@Environment(\.dynamicTypeSize) private var dynamicTypeSize

		var source: CampaignSource.Binding
		var viewState: LoadableState<ViewState>
		var primaryAction: () -> Void
		var retryAction: () -> Void

		var body: some View {
			HStack {
				switch viewState {
				case .absent:
					absentHeader
				case .loading:
					loadingHeader
				case let .error(error):
					errorHeader(error: error)
				case let .loaded(loadedData):
					if dynamicTypeSize.isAccessibilitySize == false {
						Image(source.chargeSession.isAbsent ? .place : .bolt)
					}
					switch loadedData {
					case let .campaign(campaign):
						offerHeader(campaign: campaign)
					case let .chargeSession(session):
						chargeSessionHeader(session: session)
					}
				}
			}
			.padding(8)
			.frame(maxWidth: .infinity, alignment: .leading)
			.typography(.copy(size: .small), weight: .bold)
			.foregroundStyle(.primaryContent)
			.background(.canvas)
		}

		@ViewBuilder private func offerHeader(campaign: Campaign) -> some View {
			AdaptiveHStack { isHorizontalStack in
				ViewThatFits(in: .horizontal) {
					Text("Best deal around you", bundle: .elvahCharge)
					Text("Best deal", bundle: .elvahCharge)
				}

				if isHorizontalStack {
					Spacer()
				}

				TimelineView(.periodic(from: .now, by: 1)) { context in
					if let offer = campaign.chargeSite.earliestEndingOffer {
						OfferEndLabel(
							offer: offer,
							referenceDate: context.date,
							prefix: "Ends in ",
							primaryColor: .brand
						)
						.typography(.copy(size: .small), weight: .bold)
						.foregroundStyle(offer.hasEnded ? .secondaryContent : .brand)
					}
				}
			}
		}

		private func formatTimeLeft(_ duration: Duration) -> String {
			// If less than 1 minute remaining, show seconds
			if duration.components.seconds < 60 {
				return duration.formatted(
					.units(
						allowed: [.seconds],
						maximumUnitCount: 1
					)
				)
			}

			// Otherwise show larger units
			return duration.formatted(
				.units(
					allowed: [.weeks, .days, .hours, .minutes],
					maximumUnitCount: 2
				)
			)
		}

		@ViewBuilder private var absentHeader: some View {
			Text(verbatim: "No data")
				.redacted(reason: .placeholder)
		}

		@ViewBuilder private var loadingHeader: some View {
			AdaptiveHStack { isHorizontalStack in
				if source.chargeSession.isLoading {
					chargeSessionInProgressLabel
				} else {
					Text("Loading data…", bundle: .elvahCharge)
				}
				if isHorizontalStack {
					Spacer()
				}
			}
		}

		@ViewBuilder private func errorHeader(error: any Error) -> some View {
			AdaptiveHStack { isHorizontalStack in
				if source.chargeSession.isError {
					chargeSessionInProgressLabel
				}
				if isHorizontalStack {
					Spacer()
				}
				if source.kind?.isReloadable == true || source.chargeSession.isError {
					Button("Try again", bundle: .elvahCharge, action: retryAction)
						.foregroundStyle(.brand)
				}
			}
		}

		@ViewBuilder private func chargeSessionHeader(session: ChargeSession) -> some View {
			TimelineView(.periodic(from: .now, by: 1)) { context in
				var elapsedSeconds: Duration {
					if let chargeSessionContext {
						return Duration.seconds(context.date.timeIntervalSince(chargeSessionContext.startedAt))
					}
					return Duration.seconds(session.duration)
				}

				AdaptiveHStack { isHorizontalStack in
					chargeSessionInProgressLabel
					if isHorizontalStack {
						Spacer()
					}
					Text("\(elapsedSeconds.formatted(.units()))", bundle: .elvahCharge)
						.foregroundStyle(.brand)
				}
			}
		}

		@ViewBuilder private var chargeSessionInProgressLabel: some View {
			Text("Charging…", bundle: .elvahCharge)
		}
	}
}
