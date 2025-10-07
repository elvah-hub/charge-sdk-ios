// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
extension ChargeSessionFeature {
	struct Content: View {
		@Default(.chargeSessionContext) private var chargeSessionContext
		@Environment(\.dynamicTypeSize) private var dynamicTypeSize
		@Environment(\.navigationRoot) private var navigationRoot
		@Namespace private var namespace

		@Loadable<PaymentSummary> private var paymentSummary

		let status: SessionStatus
		let progress: Double
		let attempts: Int
		@ObservedObject var router: Router
		let onAction: (_ action: Action) -> Void

		var body: some View {
			VStack(spacing: .size(.M)) {
				if dynamicTypeSize.isAccessibilitySize {
					ScrollView {
						content
					}
				} else {
					content
				}
				footer
			}
			.animation(.snappy, value: status)
			.animation(.snappy, value: paymentSummary)
			.frame(maxWidth: .infinity)
		}

		@ViewBuilder private var content: some View {
			VStack(spacing: .size(.M)) {
				activityIndicator
					.frame(maxHeight: .infinity)
				if case let .stopped(session) = status, let chargeSessionContext {
					ChargeSessionStoppedComponent(
						session: session,
						site: chargeSessionContext.site,
						offer: chargeSessionContext.signedOffer.offer,
						paymentSummary: $paymentSummary,
					)
				}
			}
		}

		@ViewBuilder private var activityIndicator: some View {
			if let contentState = status.contentState {
				VStack(spacing: .size(.L)) {
					VStack(spacing: .size(.XS)) {
						let iconSize = status.isCharging && status.hasConsumption ? 20.0 : 35

						icon(for: status)
							.frame(width: iconSize, height: iconSize)
							.transition(.opacity.combined(with: .scale))
							.foregroundStyle(status.isError ? .red : .brand)

						if case let .charging(session) = status {
							ChargeSessionMetricsComponent(status: status, session: session)
								.transition(.opacity.combined(with: .scale))
						}
					}
					.progressRing(contentState.progressRingMode)

					VStack(spacing: .size(.S)) {
						if let title = contentState.title {
							ViewThatFits(in: .vertical) {
								title.typography(.title(size: .medium), weight: .bold)
								title.typography(.copy(size: .medium), weight: .bold)
							}
							.foregroundStyle(.primaryContent)
							.frame(maxWidth: .infinity)
							.contentTransition(.interpolate)
							.transition(.opacity.combined(with: .offset(y: 40)).combined(with: .scale(scale: 1.2)))
						}

						if let message = contentState.message {
							ViewThatFits(in: .vertical) {
								message.typography(.copy(size: .medium))
								message.typography(.copy(size: .small))
							}
							.foregroundStyle(.secondaryContent)
							.frame(maxWidth: .infinity)
							.contentTransition(.interpolate)
							.transition(.opacity.combined(with: .offset(y: 40)).combined(with: .scale(scale: 1.2)))
						}
					}
					.frame(maxWidth: 300)
				}
				.transformEffect(.identity)
				.padding(.M)
				.multilineTextAlignment(.center)
			}
		}

		@ViewBuilder private func icon(for contentState: ChargeSessionFeature.SessionStatus) -> some View {
			switch contentState {
			case .started,
			     .stopped:
				Image(.checkmark)
					.resizable()
					.aspectRatio(contentMode: .fit)
			case .charging,
			     .sessionLoading,
			     .startRequested:
				Image(.bolt)
					.resizable()
					.aspectRatio(contentMode: .fit)
			case .stopRequested,
			     .startRejected,
			     .stopRejected,
			     .unknownError:
				Image(.boltSlash)
					.resizable()
					.aspectRatio(contentMode: .fit)
			case .unauthorized:
				Image(systemName: "lock.fill")
					.resizable()
					.aspectRatio(contentMode: .fit)
			}
		}

		@ViewBuilder private var footer: some View {
			VStack(spacing: .size(.M)) {
				ButtonStack {
					switch status {
					case .sessionLoading:
						EmptyView()
					case .unauthorized:
						tryAgainButton
						EmptyView()
					case .unknownError:
						tryAgainButton
						EmptyView()
					case .startRequested:
						EmptyView()
					case .startRejected:
						tryAgainButton
						EmptyView()
					case .started:
						EmptyView()
					case .charging:
						if let chargeSessionContext, chargeSessionContext.signedOffer.price.hasAdditionalCost {
							additionalCostsDisclaimerBox(offer: chargeSessionContext.signedOffer.offer)
						}
						Button("Stop charging", bundle: .elvahCharge) {
							onAction(.stop)
						}
						.buttonStyle(.primary)
					case .stopRequested:
						EmptyView()
					case .stopRejected:
						tryAgainButton
						EmptyView()
					case .stopped:
						Button("Done", bundle: .elvahCharge) {
							navigationRoot.dismiss()
							chargeSessionContext = nil
						}
						.buttonStyle(.primary)
					}

					VStack(spacing: .size(.XXS)) {
						CPOLogo(url: chargeSessionContext?.organisationDetails.logoUrl)
					}
				}
			}
			.padding(.horizontal, .M)
		}

		@ViewBuilder private func additionalCostsDisclaimerBox(offer: ChargeOffer) -> some View {
			Button {
				router.additionalCostsInfo = offer
			} label: {
				CustomBox {
					HStack(alignment: .top, spacing: .size(.XS)) {
						Image(.monetizationOn)
							.foregroundStyle(.primaryContent)
							.offset(y: -4)
							.hiddenForLargeDynamicTypeSize()
						VStack(alignment: .leading, spacing: .size(.XXS)) {
							Text("Additional costs apply at this charge point.")
								.typography(.copy(size: .medium))
								.foregroundStyle(.secondaryContent)
								.fixedSize(horizontal: false, vertical: true)
								.dynamicTypeSize(...(.xxxLarge))
							Text("Learn more")
								.typography(.copy(size: .medium), weight: .bold)
								.underline()
								.fixedSize(horizontal: false, vertical: true)
								.dynamicTypeSize(...(.xxLarge))
						}
						.frame(maxWidth: .infinity, alignment: .leading)
					}
				}
			}
			.buttonStyle(.plain)
		}

		@ViewBuilder private var tryAgainButton: some View {
			Button("Try again", bundle: .elvahCharge) {
				onAction(.resetSessionObservation)
			}
			.buttonStyle(.primary)
		}

		// MARK: - Helpers

		private var showProgressBar: Bool {
			switch status {
			case .startRequested:
				true
			case .started:
				true
			case .charging:
				false
			default:
				false
			}
		}
	}
}

@available(iOS 16.0, *)
extension ChargeSessionFeature.Content {
	enum Action {
		case abort
		case restart
		case stop
		case resetSessionObservation
	}
}

@available(iOS 26.0, *)
#Preview {
	@Previewable @State var status: ChargeSessionFeature.SessionStatus = .charging(session: .mock(status: .started, consumption: 10))

	NavigationStack {
		VStack {
			ChargeSessionFeature.Content(
				status: status,
				progress: 0.5,
				attempts: 1,
				router: .init(),
			) { _ in }
				.frame(maxHeight: .infinity, alignment: .bottom)
			Picker(selection: $status) {
				Text(verbatim: "Started").tag(ChargeSessionFeature.SessionStatus.started)
				Text(verbatim: "Charging 0 kWh")
					.tag(ChargeSessionFeature.SessionStatus.charging(session: .mock(status: .started, consumption: 0)))
				Text(verbatim: "Charging, 10 kWh")
					.tag(ChargeSessionFeature.SessionStatus.charging(session: .mock(status: .started, consumption: 10)))
				Text(verbatim: "Stopped").tag(ChargeSessionFeature.SessionStatus.stopped(session: .mock(status: .stopped)))
				Text(verbatim: "Stop Failed").tag(ChargeSessionFeature.SessionStatus.stopRejected)
			} label: {
				Text(verbatim: "")
			}
		}
	}
	.onAppear {
		Defaults[.chargeSessionContext] = ChargeSessionContext(
			site: .mock,
			signedOffer: .mockAvailable,
			organisationDetails: .mock,
			authentication: .mock,
			paymentId: "",
			startedAt: Date(),
		)
	}
	.preferredColorScheme(.dark)
	.withFontRegistration()
	.withMockEnvironmentObjects()
}
