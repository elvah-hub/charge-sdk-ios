// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
extension ChargeSessionFeature {
	struct Content: View {
		@Default(.chargeSessionContext) private var chargeSessionContext
		@Environment(\.navigationRoot) private var navigationRoot
		@Namespace private var namespace

		@Loadable<PaymentSummary> private var paymentSummary

		let status: SessionStatus
		let progress: Double
		let attempts: Int
		@ObservedObject var router: Router
		let onAction: (_ action: Action) -> Void

		var body: some View {
			VStack {
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
				footer
			}
			.animation(.smooth, value: status)
			.animation(.smooth, value: paymentSummary)
			.frame(maxWidth: .infinity)
		}

		@ViewBuilder private func icon(for contentState: ChargeSessionFeature.SessionStatus) -> some View {
			switch contentState {
			case .started:
				Image(.checkmark)
			case .charging:
				Image(.bolt)
			case .stopRequested:
				Image(.boltSlash)
			case .stopped:
				Image(.checkmark)
			default:
				Image(.bolt)
			}
		}

		@ViewBuilder private var activityIndicator: some View {
			if let contentState = status.contentState {
				VStack(spacing: .size(.L)) {
					VStack(spacing: .size(.XS)) {
						if #available(iOS 17.0, *) {
							icon(for: status)
								.typography(status.isCharging ? .copy(size: .small) : .title(size: .medium))
								.contentTransition(.symbolEffect)
								.foregroundStyle(.brand)
						} else {
							icon(for: status)
								.typography(status.isCharging ? .copy(size: .small) : .title(size: .medium))
								.foregroundStyle(.brand)
						}
						if case let .charging(session) = status {
							ChargeSessionMetricsComponent(status: status, session: session)
								.transition(.opacity.combined(with: .scale))
						}
					}
					.progressRing(contentState.progressRingMode)

					VStack(spacing: .size(.S)) {
						if let title = contentState.title {
							title
								.typography(.title(size: .medium), weight: .bold)
								.foregroundStyle(.primaryContent)
								.contentTransition(.interpolate)
								.fixedSize(horizontal: false, vertical: true)
								.frame(maxWidth: .infinity)
								.transition(.opacity.combined(with: .scale(scale: 1.2)))
						}

						if let message = contentState.message {
							message
								.typography(.copy(size: .medium))
								.foregroundStyle(.secondaryContent)
								.contentTransition(.interpolate)
								.fixedSize(horizontal: false, vertical: true)
								.frame(maxWidth: .infinity)
								.transition(.opacity.combined(with: .scale(scale: 1.2)))
						}
					}
					.frame(maxWidth: 300)
				}
				.padding(.horizontal, .M)
				.multilineTextAlignment(.center)
				.transformEffect(.identity)
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
						supportButton
					}
				}
			}
			.padding(.horizontal, .M)
		}

		@ViewBuilder private var tryAgainButton: some View {
			Button("Try again", bundle: .elvahCharge) {
				onAction(.resetSessionObservation)
			}
			.buttonStyle(.primary)
		}

		@ViewBuilder private var supportButton: some View {
			Button("Support", bundle: .elvahCharge) {
				router.showSupport = true
			}
			.buttonStyle(.textPrimary)
			.matchedGeometryEffect(id: 0, in: namespace)
			.transition(.scale(scale: 1)) // Prevents fade animation
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

@available(iOS 16.0, *)
#Preview {
	NavigationStack {
		ChargeSessionFeature.Content(
			status: .stopped(session: .mock(status: .stopped)),
			progress: 0.5,
			attempts: 1,
			router: .init(),
		) { _ in }
			.frame(maxHeight: .infinity, alignment: .bottom)
	}
	.preferredColorScheme(.dark)
	.withFontRegistration()
	.withMockEnvironmentObjects()
}
