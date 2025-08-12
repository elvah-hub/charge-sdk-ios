// Copyright © elvah. All rights reserved.

import Defaults
import SwiftUI

@available(iOS 16.0, *)
extension ChargeBannerComponent {
	struct Header: View {
		@Default(.chargeSessionContext) private var chargeSessionContext
		@Environment(\.dynamicTypeSize) private var dynamicTypeSize

		var source: ChargeBannerSource.Binding
		var viewState: LoadableState<ViewState>
		var primaryAction: () -> Void
		var retryAction: () -> Void

		var body: some View {
			if case let .loaded(loadedData) = viewState, loadedData.needsHeader {
				HStack {
					switch loadedData {
					case let .chargeOffer(offer, chargeSite):
						offerHeader(offer: offer, chargeSite: chargeSite)
					case let .chargeSession(session):
						chargeSessionHeader(session: session)
					}
				}
				.padding(8)
				.frame(maxWidth: .infinity, alignment: .leading)
				.typography(.copy(size: .small), weight: .bold)
				.foregroundStyle(.primaryContent)
				.background(.canvas)
			} else if case let .error(error) = viewState {
				HStack {
					errorHeader(error: error)
				}
				.padding(8)
				.foregroundStyle(.primaryContent)
				.background(.canvas)
			}
		}

		@ViewBuilder private func offerHeader(offer: ChargeOffer, chargeSite: ChargeSite) -> some View {
			TimelineView(.periodic(from: .now, by: 1)) { context in
				OfferEndLabel(
					offer: offer,
					referenceDate: context.date,
					prefix: "Offer ends in ",
					primaryColor: .brand
				)
				.typography(.copy(size: .small), weight: .bold)
				.foregroundStyle(offer.isAvailable ? .brand : .secondaryContent)
			}
			.frame(maxWidth: .infinity)
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
			.typography(.copy(size: .small), weight: .bold)
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
					Text(verbatim: elapsedSeconds.formatted(.units()))
						.foregroundStyle(.brand)
				}
			}
			.typography(.copy(size: .small), weight: .bold)
		}

		@ViewBuilder private var chargeSessionInProgressLabel: some View {
			Text("Charging…", bundle: .elvahCharge)
				.typography(.copy(size: .small), weight: .bold)
		}
	}
}
