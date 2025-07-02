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
				if case let .stopped(sessionStorage, session) = status, let sessionStorage {
					ChargeSessionStoppedComponent(
						session: session,
						site: sessionStorage.site,
						deal: sessionStorage.deal
					)
				} else {
					VStack(spacing: Size.XL.size) {
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
				case .loading:
					EmptyView()
				case .unauthorized:
					EmptyView()
				case .unknownError:
					EmptyView()
				case .activation:
					EmptyView()
				case .connection:
					EmptyView()
				case let .charging(session: session):
					ChargeSessionMetricsComponent(status: status, session: session)
				case .stopRequested:
					EmptyView()
				case .stopFailed:
					EmptyView()
				case .stopped:
					EmptyView()
				}
			}
			.foregroundStyle(.primaryContent)
			.transition(.opacity)
		}

		@ViewBuilder private var footer: some View {
			VStack(spacing: Size.L.size) {
				if showProgressBar {
					progressBar
				}

				ButtonStack {
					switch status {
					case .loading:
						EmptyView()
					case .unauthorized:
						Button("Try again", bundle: .elvahCharge) {
							onAction(.resetSessionObservation)
						}
						.buttonStyle(.primary)
					case .unknownError:
						Button("Try again", bundle: .elvahCharge) {
							onAction(.resetSessionObservation)
						}
						.buttonStyle(.primary)
					case let .activation(progress):
						if case .error = progress {
							Button("Try again", bundle: .elvahCharge) {
								onAction(.resetSessionObservation)
							}
							.buttonStyle(.secondary)
							Button("End charge session", bundle: .elvahCharge) {
								navigationRoot.dismiss()
								chargeSessionContext = nil
							}
							.buttonStyle(.primary)
						}
					case .connection:
						EmptyView()
					case .charging:
						Button("Stop charging") {
							onAction(.stop)
						}
						.buttonStyle(.primary)
					case .stopRequested:
						EmptyView()
					case .stopFailed:
						Button("Try again", bundle: .elvahCharge) {
							onAction(.stop)
						}
						.buttonStyle(.primary)
					case .stopped:
						Button("Done", bundle: .elvahCharge) {
							navigationRoot.dismiss()
							chargeSessionContext = nil
						}
						.buttonStyle(.primary)
					}

					if case .stopped = status {} else {
						Button("Support", bundle: .elvahCharge) {
							router.showSupport = true
						}
						.buttonStyle(.textPrimary)
						.matchedGeometryEffect(id: 0, in: namespace)
						.transition(.scale(scale: 1)) // Prevents fade animation
					}
				}
				DisclaimerFooter()
			}
			.padding(.M)
			.animation(.default, value: status)
		}

		@ViewBuilder private var activityIndicator: some View {
			switch status {
			case .loading,
			     .unauthorized,
			     .unknownError,
			     .activation,
			     .connection,
			     .stopRequested,
			     .stopFailed,
			     .stopped:
				let data = status.activityInfoData
				ActivityInfoComponent(state: data.state, title: data.title, message: data.message)
					.padding(.horizontal)
					.animation(.bouncy(extraBounce: 0.2), value: status)
					.alignmentGuide(VerticalAlignment.top) { dimension in
						-50
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
			case let .activation(progress: progress):
				if case .error = progress {
					return false
				}
				return true
			case .connection:
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
