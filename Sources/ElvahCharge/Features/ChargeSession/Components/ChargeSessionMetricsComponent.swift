// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
struct ChargeSessionMetricsComponent: View {
	@Default(.chargeSessionContext) private var chargeSessionContext

	let status: ChargeSessionFeature.SessionStatus
	let session: ChargeSession

	var body: some View {
		ZStack(alignment: .bottom) {
			VStack(spacing: .size(.XXS)) {
				consumption
				duration
			}
		}
		.dynamicTypeSize(...(.accessibility1))
	}

	@ViewBuilder private var consumption: some View {
		if session.hasConsumption, let formattedConsumedKWh = session.formattedConsumedKWh {
			VStack(spacing: .size(.XXS)) {
				HStack(alignment: .firstTextBaseline) {
					Text(formattedConsumedKWh)
						.contentTransition(.numericText(countsDown: false))
						.typography(.title(size: .medium), weight: .bold)
					Text("kWh")
						.typography(.copy(size: .large))
				}
				.monospacedDigit()
				.foregroundStyle(.primaryContent)
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
					.typography(.copy(size: .medium))
					.monospacedDigit()
					.foregroundStyle(.secondaryContent)
			}
		}
	}

	// MARK: - Helpers

	private var timerString: String {
		Duration.seconds(session.duration).formatted(.units())
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @State var session: ChargeSession = .mock(status: .charging)
	ChargeSessionMetricsComponent(
		status: .charging(session: session),
		session: session,
	)
	.progressRing()
	.preferredColorScheme(.dark)
	.withFontRegistration()
}
