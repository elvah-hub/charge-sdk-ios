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
	@State private var status: Status = .loading
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
					if session?.status == .stopped {
						CloseButton {
							navigationRoot.dismiss()
						}
					} else {
						MinimizeButton {
							navigationRoot.dismiss()
						}
					}
				}
				ToolbarItem(placement: .principal) {
					StyledNavigationTitle("Charge Session", bundle: .elvahCharge)
				}
			}
			.sheet(isPresented: $router.showSupport) {
				SupportBottomSheet(router: router.supportRouter)
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
			router: router
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

	private func makeStatus(session: ChargeSession?) -> Status {
		guard let session else {
			return .loading
		}

		switch session.status {
		case .startRequested,
		     .none:
			return .activation(progress: .loading)

		case .startRejected:
			return .activation(progress: .error)

		case .started:
			return .connection(progress: .initial)

		case .charging:
			return .charging(session: session)

		case .stopRequested:
			return .stopRequested

		case .stopRejected:
			return .stopFailed

		case .stopped:
			return .stopped(
				chargeSessionContext: Defaults[.chargeSessionContext],
				session: session
			)
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
	enum Status: Hashable {
		case loading
		case activation(progress: ActivationProgress)
		case connection(progress: ConnectionProgress)
		case charging(session: ChargeSession)
		case stopRequested
		case stopFailed
		case stopped(chargeSessionContext: ChargeSessionContext?, session: ChargeSession)
		case unauthorized
		case unknownError

		enum ActivationProgress: Hashable {
			case loading
			case success
			case error
		}

		enum ConnectionProgress: Hashable {
			case initial
			case delayInformation
			case success
		}
	}
}

@available(iOS 16.0, *)
extension ChargeSessionFeature {
	@MainActor
	final class Router: BaseRouter {
		@Published var path: NavigationPath = .init()
		@Published var showSupport = false

		let supportRouter: SupportBottomSheet.Router = .init()

		func dismissPresentation() {
			showSupport = false
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
			deal: .mockAvailable,
			organisationDetails: .mock,
			authentication: .mock,
			paymentId: "",
			startedAt: Date()
		)
	}
	.withMockEnvironmentObjects()
	.preferredColorScheme(.dark)
	.withFontRegistration()
}
