// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct AuthenticationExpiredFeature: View {
	@Environment(\.navigationRoot) private var navigationRoot
	@ObservedObject var router: Router

	var body: some View {
		VStack {
			ActivityInfoComponent(
				state: .error,
				title: "Payment expired",
				message: """
				Unfortunately, the time between payment and session start was too long. \
				We need you to authorize a new deposit on your payment method.
				"""
			)
			.frame(maxHeight: .infinity)
			.padding(.horizontal)
			VStack {
				VStack(spacing: Size.M.size) {
					Button("Continue", bundle: .elvahCharge) {
						navigationRoot.path = .init()
					}
					.buttonStyle(.primary)
					Button("Support", bundle: .elvahCharge) {
						router.showSupport = true
					}
					.compactControl()
					.buttonStyle(.textPrimary)
				}
			}
			.padding(.horizontal, .M)
		}
		.navigationBarBackButtonHidden()
		.background {
			Color.canvas.ignoresSafeArea()
		}
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				CloseButton {
					navigationRoot.dismiss()
				}
			}
		}
		.sheet(isPresented: $router.showSupport) {
			SupportBottomSheet(router: router.supportRouter)
		}
	}
}

@available(iOS 16.0, *)
extension AuthenticationExpiredFeature {
	@MainActor
	final class Router: BaseRouter {
		@Published var showSupport = false

		let supportRouter: SupportBottomSheet.Router = .init()

		func dismissPresentation() {
			showSupport = false
		}

		func reset() {
			dismissPresentation()
			supportRouter.reset()
		}
	}
}

@available(iOS 16.0, *)
#Preview {
	AuthenticationExpiredFeature(router: .init())
		.withFontRegistration()
}
