// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
package struct ChargeEntryFeature: View {
	@Environment(\.dismiss) private var dismiss
	@Default(.chargeSessionContext) private var chargeSessionContext
	@Process private var process
	@EnvironmentObject private var chargeProvider: ChargeProvider
	@StateObject private var router = Router()
	@State private var state: ViewState = .loading
	@State private var chargeRequest: ChargeRequest?
	@State private var showChargeSession = false

	/// A charge request that was passed into the view. The value is cached and will be used when a
	/// new charge session is allowed to start.
	private var passedChargeRequest: ChargeRequest?

	/// Initializes the ``ChargeEntryFeature`` without a charge request. The view will attempt to restore
	/// an active session, if one exists.
	package init() {}

	/// Initializes the ``ChargeEntryFeature`` with a charge request.
	///
	/// This will have the effect that this view does not need to fetch the tariffs for a given charge
	/// point. It will directly use the given request.
	///
	/// - Note: Under certain conditions, e.g. when there already is an active charge session, the
	/// given charge request will be ignored by the view and overriden by its other logic.
	/// - Parameter chargeRequest: The charge request to use.
	package init(chargeRequest: ChargeRequest) {
		passedChargeRequest = chargeRequest
	}

	package var body: some View {
		NavigationStack(path: $router.path) {
			ZStack {
				Color.canvas.ignoresSafeArea()
				if showChargeSession {
					ChargeSessionFeature(router: router.chargeSessionRouter)
				} else if let chargeRequest {
					ChargePaymentFeature(request: chargeRequest, router: router.paymentRouter)
				} else {
					if state == .missingChargeContext {
						MissingChargeContextView()
					} else {
						ChargeEntryActivityView(state: state)
					}
				}
			}
		}
		.navigationRoot(path: $router.path)
		.withSafeAreaInsets()
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.animation(.default, value: chargeRequest)
		.animation(.default, value: showChargeSession)
		.animation(.bouncy(extraBounce: 0.1), value: state)
		.task(id: passedChargeRequest?.id) {
			await prepareData()
		}
	}

	private func abortChargeAttempt() {
		chargeSessionContext = nil
		showChargeSession = false
		chargeRequest = nil
		state = .missingChargeContext
	}

	// MARK: - Data Loading

	private func prepareData() async {
		await $process.run {
			if canHandleNewChargeRequest, let passedChargeRequest {
				// Use the charge request that was passed in
				showChargeSession = false
				chargeRequest = passedChargeRequest
			} else if showChargeSession == false, chargeSessionContext != nil {
				// Restore existing charge session
				showChargeSession = true
			} else if canHandleNewChargeRequest {
				// No active charge session and no charge request that can be handled
				try await Task.sleep(for: .milliseconds(800))
				state = .missingChargeContext
			}
		}
	}

	private var canHandleNewChargeRequest: Bool {
		chargeSessionContext == nil
	}
}

@available(iOS 16.0, *)
extension ChargeEntryFeature {
	enum ViewState {
		case loading
		case missingChargeContext
		case preparingChargeRequest
		case preparedChargeRequest
		case failedToPrepareChargeRequest
	}
}

@available(iOS 16.0, *)
extension ChargeEntryFeature {
	@MainActor
	final class Router: BaseRouter {
		@Published var path = NavigationPath()

		init() {}

		let paymentRouter = ChargePaymentFeature.Router()
		let chargeSessionRouter = ChargeSessionFeature.Router()

		func reset() {
			paymentRouter.reset()
			chargeSessionRouter.reset()
			dismissPresentation()
		}

		func dismissPresentation() {}
	}
}

@available(iOS 16.0, *)
#Preview {
	ChargeEntryFeature(chargeRequest: .mock)
		.withMockEnvironmentObjects()
		.withFontRegistration()
}
