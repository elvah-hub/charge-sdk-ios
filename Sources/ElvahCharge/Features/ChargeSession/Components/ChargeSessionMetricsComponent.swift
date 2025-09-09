// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
struct ChargeSessionMetricsComponent: View {
	@Default(.chargeSessionContext) private var chargeSessionContext

	let status: ChargeSessionFeature.Status
	let session: ChargeSession

	var body: some View {
		ZStack(alignment: .bottom) {
			VStack(spacing: .size(.XXL)) {
				consumption
				duration
			}
			.transformEffect(.identity)
		}
		.dynamicTypeSize(...(.accessibility1))
		.padding(.vertical, .M)
	}

	@ViewBuilder private var consumption: some View {
		if session.hasConsumption, let formattedConsumedKWh = session.formattedConsumedKWh {
			VStack(spacing: .size(.XXS)) {
				Text(formattedConsumedKWh)
					.contentTransition(.numericText(countsDown: false))
					.typography(.title(size: .xLarge), weight: .bold)
					.monospacedDigit()
					.foregroundStyle(.primaryContent)
				Text("kWh charged", bundle: .elvahCharge)
					.typography(.copy(size: .medium))
					.foregroundStyle(.secondaryContent)
					.multilineTextAlignment(.center)
			}
		}
	}

	@ViewBuilder private var duration: some View {
		VStack(spacing: .size(.XXS)) {
			TimelineView(.periodic(from: .now, by: 1)) { context in
				var elapsedSeconds: Duration {
					if let chargeSessionContext {
						return Duration.seconds(context.date.timeIntervalSince(chargeSessionContext.startedAt))
					}
					return Duration.seconds(session.duration)
				}

				Text(elapsedSeconds.formatted(.units()))
					.typography(.title(size: .medium), weight: .bold)
					.monospacedDigit()
					.foregroundStyle(.primaryContent)
			}
			Text("Charging duration", bundle: .elvahCharge)
				.typography(.copy(size: .medium))
				.foregroundStyle(.secondaryContent)
				.multilineTextAlignment(.center)
		}
	}

	// MARK: - Helpers

	private var timerString: String {
		return Duration.seconds(session.duration).formatted(.units())
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @State var session: ChargeSession = .mock(status: .charging)
	ChargeSessionMetricsComponent(
		status: .charging(session: session),
		session: session
	)
	.preferredColorScheme(.dark)
	.withFontRegistration()
}
