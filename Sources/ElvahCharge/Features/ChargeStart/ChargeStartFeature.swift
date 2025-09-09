// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
struct ChargeStartFeature: View {
	@Environment(\.dynamicTypeSize) private var dynamicTypeSize
	@Environment(\.navigationRoot) private var navigationRoot
	@EnvironmentObject private var chargeProvider: ChargeProvider
	@Default(.chargeSessionContext) private var chargeSessionContext
	@Process private var sessionStart
	@State private var showSuccessBanner = true

	let request: AuthenticatedChargeRequest
	@ObservedObject var router: Router

	var body: some View {
		VStack(spacing: .size(.XXXL)) {
			Spacer()
			header
			requestInformation
			Spacer()
		}
		.padding(.horizontal, .M)
		.background(.canvas)
		.safeAreaInset(edge: .top) {
			if showSuccessBanner {
				successBanner
			}
		}
		.animation(.default, value: showSuccessBanner)
		.safeAreaInset(edge: .bottom) {
			FooterView {
				VStack(spacing: .size(.L)) {
					startSlider
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				CloseButton {
					navigationRoot.dismiss()
				}
			}
		}
		.navigationBarBackButtonHidden()
		.navigationDestination(for: Router.Destination.self) { [
			authenticationExpiredFeatureRouter = router.authenticationExpiredFeatureRouter,
			chargeSessionRouter = router.chargeSessionRouter
		] destination in
			switch destination {
			case .chargeAuthenticationExpired:
				AuthenticationExpiredFeature(router: authenticationExpiredFeatureRouter)
			case .chargeSession:
				ChargeSessionFeature(router: chargeSessionRouter)
			}
		}
		.genericErrorBottomSheet(isPresented: $router.showGenericError)
		.sheet(item: $router.startSessionInfo) { info in
			StartChargeInfoComponent(chargePoint: info.chargePoint)
		}
		.task {
			try? await Task.sleep(for: .seconds(3))
			showSuccessBanner = false
		}
	}

	@ViewBuilder private var successBanner: some View {
		HStack(spacing: .size(.M)) {
			Image(.checkmarkCircle)
			Text("Authorization successful", bundle: .elvahCharge)
				.typography(.copy(size: .small), weight: .bold)
			Spacer()
			Button {
				showSuccessBanner = false
			} label: {
				Image(.close)
			}
			.buttonStyle(.plain)
		}
		.padding(.S)
		.frame(maxWidth: .infinity)
		.foregroundStyle(.onSuccess)
		.background(.success, in: .rect(cornerRadius: 12))
		.padding(.horizontal, .S)
		.dynamicTypeSize(...(.accessibility1))
	}

	@ViewBuilder private var header: some View {
		VStack(spacing: 20) {
			CPOLogo(url: request.paymentContext.organisationDetails.logoUrl)
			Text(
				"Connect your electric vehicle now and start the charging process.",
				bundle: .elvahCharge
			)
			.typography(.title(size: .small), weight: .bold)
			.fixedSize(horizontal: false, vertical: true)
			.foregroundStyle(.primaryContent)
			.padding(.horizontal, .XL)
		}
		.frame(maxWidth: .infinity)
		.dynamicTypeSize(...(.xxxLarge))
		.multilineTextAlignment(.center)
		.listRowBackground(Color.clear)
	}

	@ViewBuilder private var requestInformation: some View {
		VStack(spacing: .size(.M)) {
			ChargePointIdentifierView(point: request.signedOffer.chargePoint)
			Button("Is the charge point locked?", bundle: .elvahCharge) {
				router.startSessionInfo = .init(chargePoint: request.signedOffer.chargePoint)
			}
			.buttonStyle(.textPrimary)
		}
	}

	@ViewBuilder private var startSlider: some View {
		ChargeSliderView(
			title: dynamicTypeSize.isAccessibilitySize ? "Start" : "Start charging process"
		) {
			startChargeSession()
			// Wait before return to delay slider reset
			try? await Task.sleep(for: .seconds(1))
		}
		.frame(height: dynamicTypeSize.isAccessibilitySize ? 80 : 55)
	}

	private func startChargeSession() {
		$sessionStart.run {
			do {
				try await chargeProvider.start(authentication: request.authentication)
				chargeSessionContext = .from(request: request)
				navigationRoot.path.append(Router.Destination.chargeSession)
			} catch NetworkError.unauthorized {
				navigationRoot.path.append(Router.Destination.chargeAuthenticationExpired)
			} catch {
				router.showGenericError = true
			}
		}
	}
}

@available(iOS 16.0, *)
extension ChargeStartFeature {
	final class Router: BaseRouter {
		enum Destination: Hashable {
			case chargeSession
			case chargeAuthenticationExpired
		}

		struct StartSessionInfo: Identifiable {
			var id = UUID()
			var chargePoint: ChargePoint
		}

		@Published var showGenericError = false
		@Published var startSessionInfo: StartSessionInfo?
		@Published var showSupport = false

		let supportSheetRouter = SupportFeature.Router()
		let chargeSessionRouter = ChargeSessionFeature.Router()
		let authenticationExpiredFeatureRouter = AuthenticationExpiredFeature.Router()

		func dismissPresentation() {
			showGenericError = false
			startSessionInfo = nil
			showSupport = false
		}

		func reset() {
			chargeSessionRouter.reset()
			dismissPresentation()
		}
	}
}

@available(iOS 16.0, *)
#Preview {
	NavigationStack {
		ChargeStartFeature(request: .mock, router: .init())
	}
	.withFontRegistration()
	.withMockEnvironmentObjects()
	.preferredColorScheme(.dark)
}
