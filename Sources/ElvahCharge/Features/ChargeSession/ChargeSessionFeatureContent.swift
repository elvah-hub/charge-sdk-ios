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

		let status: Status
		let progress: Double
		let attempts: Int
		@ObservedObject var router: Router
		let onAction: (_ action: Action) -> Void

		var body: some View {
			VStack {
				if case let .stopped(session) = status, let chargeSessionContext {
					ChargeSessionStoppedComponent(
						session: session,
						site: chargeSessionContext.site,
						offer: chargeSessionContext.signedOffer.offer
					)
				} else {
					VStack(spacing: .size(.XL)) {
						header
						page
					}
					.frame(maxHeight: .infinity)
				}
				footer
			}
		}

		@ViewBuilder private var header: some View {
			CPOLogo(url: chargeSessionContext?.organisationDetails.logoUrl)
		}

		@ViewBuilder private var page: some View {
			if case .stopped = status {} else {
				activityIndicator
			}

			Group {
				switch status {
				case let .charging(session: session):
					ChargeSessionMetricsComponent(status: status, session: session)
				default:
					EmptyView()
				}
			}
			.foregroundStyle(.primaryContent)
			.transition(.opacity)
		}

		@ViewBuilder private var footer: some View {
			VStack(spacing: .size(.L)) {
				if showProgressBar {
					progressBar
				}

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

					if case .stopped = status {} else {
						supportButton
					}
				}
			}
			.padding(.M)
			.animation(.default, value: status)
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

		@ViewBuilder private var activityIndicator: some View {
			switch status {
			case .sessionLoading,
			     .unauthorized,
			     .unknownError,
			     .startRequested,
			     .startRejected,
			     .started,
			     .stopRequested,
			     .stopRejected,
			     .stopped:
				if let data = status.activityInfoData {
					ActivityInfoComponent(state: data.state, title: data.title, message: data.message)
						.padding(.horizontal)
						.animation(.bouncy(extraBounce: 0.2), value: status)
						.alignmentGuide(VerticalAlignment.top) { dimension in
							-50
						}
				}
			case .charging:
				EmptyView()
			}
		}

		@ViewBuilder private var progressBar: some View {
			ProgressView(value: progress, total: 1)
				.progressViewStyle(.charge)
				.padding(.horizontal, .XL)
		}

		// MARK: - Helpers

		private var showProgressBar: Bool {
			switch status {
			case .startRequested:
				return true
			case .started:
				return true
			case .charging:
				return false
			default:
				return false
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
			status: .unauthorized,
			progress: 0.5,
			attempts: 1,
			router: .init()
		) { _ in }
			.frame(maxHeight: .infinity, alignment: .bottom)
	}
	.preferredColorScheme(.dark)
	.withFontRegistration()
}
