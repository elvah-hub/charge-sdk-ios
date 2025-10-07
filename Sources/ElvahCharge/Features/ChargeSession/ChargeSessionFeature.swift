// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
struct ChargeSessionFeature: View {
	@Environment(\.navigationRoot) private var navigationRoot
	@EnvironmentObject private var chargeProvider: ChargeProvider

	@Default(.chargeSessionContext) private var chargeSessionContext
	@Process private var process
	@Process private var sessionRefresh
	@TaskIdentifier private var sessionObservationId

	@State private var session: ChargeSession?
	@State private var status: SessionStatus = .sessionLoading
	@State private var progress: Double = 0
	@State private var attempts = 1

	@ObservedObject var router: Router

	var body: some View {
		content
			.background(.canvas)
			.navigationBarBackButtonHidden()
			.navigationTitle("")
			.navigationBarTitleDisplayMode(.inline)
			.toolbarBackground(.canvas, for: .navigationBar)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					MinimizeButton {
						navigationRoot.dismiss()
					}
				}
				ToolbarItem(placement: .principal) {
					StyledNavigationTitle("Charge Session", bundle: .elvahCharge)
				}
				ToolbarItem(placement: .topBarTrailing) {
					Menu {
						Button {
							router.showSupport = true
						} label: {
							Label {
								Text("Contact support", bundle: .elvahCharge)
							} icon: {
								Image(.agent)
							}
						}
						Button("Stop charging", systemImage: "xmark", role: .destructive) {
							navigationRoot.dismiss()
							chargeSessionContext = nil
						}
					} label: {
						Image(systemName: "ellipsis")
							.foregroundStyle(.primaryContent)
					}
				}
			}
			.sheet(isPresented: $router.showSupport) {
				SupportFeature(router: router.supportRouter)
			}
			.sheet(item: $router.additionalCostsInfo) { offer in
				AdditionalCostsBottomSheet(offer: offer)
			}
			.genericErrorBottomSheet(isPresented: $router.showGenericError)
			.onChange(of: process) { process in
				if case let .failed(_, error) = process {
					Elvah.internalLogger.error("Charge Session Error: \(error)")
					router.showGenericError = true
				}
			}
			.onChange(of: sessionRefresh) { sessionRefresh in
				if let error = sessionRefresh.error {
					withAnimation {
						if let error = error as? NetworkError, error == .unauthorized {
							status = .unauthorized
						} else {
							status = .unknownError
						}
					}
				}
			}
			.task(id: sessionObservationId) {
				await $sessionRefresh.run {
					try await sessionRefreshLoop()
				}
			}
	}

	@ViewBuilder private var content: some View {
		ChargeSessionFeature.Content(
			status: status,
			progress: progress,
			attempts: attempts,
			router: router,
		) { action in
			switch action {
			case .abort:
				chargeSessionContext = nil
				navigationRoot.dismiss()
			case .restart:
				$process.run {
					try await restartSession()
				}
			case .stop:
				$process.run {
					try await stopSession()
				}
			case .resetSessionObservation:
				update(session: session) // Reset session to last known state
				$sessionObservationId.new()
			}
		}
	}

	private func update(session: ChargeSession?) {
		withAnimation {
			status = makeStatus(session: session)
			progress = makeProgress()
		}
	}

	private func makeStatus(session: ChargeSession?) -> SessionStatus {
		guard let session else {
			return .sessionLoading
		}

		switch session.status {
		case .startRequested,
		     .none:
			return .startRequested

		case .startRejected:
			return .startRejected

		case .started:
			return .started

		case .charging:
			return .charging(session: session)

		case .stopRequested:
			return .stopRequested

		case .stopRejected:
			return .stopRejected

		case .stopped:
			return .stopped(session: session)
		}
	}

	private func makeProgress() -> Double {
		guard let startedAt = chargeSessionContext?.startedAt else {
			return 0
		}
		let secondsSinceInit = Date().timeIntervalSince(startedAt)
		return max(0, min(1, secondsSinceInit / 120))
	}

	private func sessionRefreshLoop() async throws {
		guard let authentication = chargeSessionContext?.authentication else {
			return
		}

		for try await session in await chargeProvider.sharedSessionUpdates(with: authentication) {
			update(session: session)
		}
	}

	private func stopSession() async throws {
		guard let authentication = chargeSessionContext?.authentication else {
			return
		}

		try await chargeProvider.stop(authentication: authentication)
		session = try await chargeProvider.session(authentication: authentication)
		update(session: session)
	}

	private func restartSession() async throws {
		guard let authentication = chargeSessionContext?.authentication else {
			return
		}

		try await chargeProvider.start(authentication: authentication)
		session = try await chargeProvider.session(authentication: authentication)
		update(session: session)
	}
}

@available(iOS 16.0, *)
extension ChargeSessionFeature {
	enum SessionStatus: Hashable {
		case sessionLoading
		case startRequested
		case startRejected
		case started
		case charging(session: ChargeSession)
		case stopRequested
		case stopRejected
		case stopped(session: ChargeSession)
		case unauthorized
		case unknownError

		var isCharging: Bool {
			switch self {
			case .charging:
				true
			default:
				false
			}
		}

		var isError: Bool {
			switch self {
			case .startRejected,
			     .stopRejected,
			     .unauthorized,
			     .unknownError:
				true
			default:
				false
			}
		}

		var hasConsumption: Bool {
			switch self {
			case let .charging(session):
				session.hasConsumption
			default:
				false
			}
		}
	}

	struct ContentState: Equatable {
		var progressRingMode: ProgressRing.Mode
		var title: Text?
		var message: Text?

		init(
			progressRingMode: ProgressRing.Mode,
			title: LocalizedStringKey? = nil,
			message: LocalizedStringKey? = nil,
		) {
			self.progressRingMode = progressRingMode

			if let title {
				self.title = Text(title, bundle: .elvahCharge)
			}

			if let message {
				self.message = Text(message, bundle: .elvahCharge)
			}
		}
	}
}

@available(iOS 16.0, *)
extension ChargeSessionFeature {
	final class Router: BaseRouter {
		@Published var path: NavigationPath = .init()
		@Published var showSupport = false
		@Published var additionalCostsInfo: ChargeOffer?
		@Published var showGenericError = false

		let supportRouter: SupportFeature.Router = .init()

		func dismissPresentation() {
			showSupport = false
			showGenericError = false
			additionalCostsInfo = nil
		}

		func reset() {
			supportRouter.reset()
			dismissPresentation()
			path = .init()
		}
	}
}

@available(iOS 16.0, *)
#Preview {
	let session = ChargeSession.mock(status: .charging)
	NavigationStack {
		ChargeSessionFeature(router: .init())
	}
	.environmentObject(ChargeProvider.mock(sessionStatus: session.status!))
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
	.withMockEnvironmentObjects()
	.preferredColorScheme(.dark)
	.withFontRegistration()
}
