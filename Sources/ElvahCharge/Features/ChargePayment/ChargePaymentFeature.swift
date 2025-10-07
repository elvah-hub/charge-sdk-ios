// Copyright © elvah. All rights reserved.

import PassKit
import Stripe
import StripePaymentSheet
import SwiftUI

#if canImport(Core)
	import Core
#endif

@available(iOS 16.0, *)
struct ChargePaymentFeature: View {
	@Environment(\.dynamicTypeSize) private var dynamicTypeSize
	@Environment(\.navigationRoot) private var navigationRoot
	@EnvironmentObject private var chargeSettlementProvider: ChargeSettlementProvider
	@Process private var payment
	@State private var paymentSheet = PaymentSheet.empty
	@State private var paymentSheetContinuation: CheckedContinuation<PaymentSheetResult, Never>?

	let request: ChargeRequest
	@ObservedObject var router: Router

	var body: some View {
		ScrollView {
			VStack(spacing: .size(.S)) {
				EvseIdBox(for: request.signedOffer)
					.padding(.vertical, .L)
				costInformation
			}
		}
		.background(.canvas)
		.scrollContentBackground(.hidden)
		.animation(.default, value: payment)
		.safeAreaInset(edge: .bottom) {
			footer
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbarBackground(.canvas, for: .navigationBar)
		.toolbar {
			ToolbarItem(placement: .principal) {
				StyledNavigationTitle("Charge now")
			}
			ToolbarItem(placement: .topBarLeading) {
				CloseButton {
					navigationRoot.dismiss()
				}
			}
		}
		.navigationDestination(for: Router.Destination.self) { [
			chargeStartRouter = router.chargeStartRouter,
		] destination in
			switch destination {
			case let .chargeStart(request):
				ChargeStartFeature(request: request, router: chargeStartRouter)
			}
		}
		.genericErrorBottomSheet(isPresented: $router.showGenericError)
		.paymentSheet(
			isPresented: $router.showPaymentSheet,
			paymentSheet: paymentSheet,
			onCompletion: { result in
				paymentSheetContinuation?.resume(returning: result)
				paymentSheetContinuation = nil
			},
		)
		.sheet(isPresented: $router.showOfferUnavailableSheet) {
			OfferEndedBottomSheet()
		}
	}

	@ViewBuilder private var costInformation: some View {
		CustomSectionStack {
			AdditionalCostsBoxComponent(offer: request.signedOffer.offer)
		}
		.padding(16)
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	@ViewBuilder private var footer: some View {
		FooterView {
			VStack(spacing: .size(.M)) {
				Button {
					if request.signedOffer.isAvailable {
						$payment.run {
							await pay()
						}
					} else {
						router.showOfferUnavailableSheet = true
					}
				} label: {
					ViewThatFits(in: .horizontal) {
						Text("Pay with Credit Card", bundle: .elvahCharge)
						Text("Pay Now", bundle: .elvahCharge)
					}
				}
				.buttonStyle(.primary)
				.disabled(payment.isRunning)
				Button {
					router.showLegalLinkOptions = true
				} label: {
					let terms = Text("Terms of Service & Charging", bundle: .elvahCharge).underline()
					let privacyPolicy = Text("Privacy Policy", bundle: .elvahCharge).underline()
					let companyName = request.paymentContext.organisationDetails.companyName ?? "CPO"
					Text(
						"'\(companyName)' \(terms) as well as our \(privacyPolicy) apply",
						bundle: .elvahCharge,
					)
					.typography(.copy(size: .small))
					.foregroundStyle(.secondaryContent)
					.multilineTextAlignment(.center)
					.frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? nil : 250)
					.dynamicTypeSize(...(.xxxLarge))
				}
				.disabled(request.paymentContext.organisationDetails.hasLegalUrls == false)
				.confirmationDialog(
					"Terms of Service and Charging",
					isPresented: $router.showLegalLinkOptions,
				) {
					Button("Terms of Service and Charging", bundle: .elvahCharge) {
						if let url = request.paymentContext.organisationDetails.termsOfConditionUrl {
							UIApplication.shared.open(url)
						}
					}
					Button("Privacy Policy", bundle: .elvahCharge) {
						if let url = request.paymentContext.organisationDetails.privacyUrl {
							UIApplication.shared.open(url)
						}
					}
					Button("Cancel", role: .cancel, bundle: .elvahCharge) {
						router.showLegalLinkOptions = false
					}
				}
				CPOLogo(url: request.paymentContext.organisationDetails.logoUrl)
			}
		}
	}

	private func pay() async {
		do {
			let paymentContext = request.paymentContext
			let stripePaymentResult: PaymentSheetResult

			switch Elvah.configuration.environment {
			case .simulation:
				stripePaymentResult = .completed
			default:
				// Set the Stripe connected account to the correct value from the initiated payment response
				STPAPIClient.shared.stripeAccount = paymentContext.accountId

				// Show Stripe's payment sheet and wait for the result
				paymentSheet = PaymentSheet.from(clientSecret: paymentContext.clientSecret)
				stripePaymentResult = await withCheckedContinuation { continuation in
					paymentSheetContinuation = continuation
					router.showPaymentSheet = true
				}
			}

			switch stripePaymentResult {
			case .completed:
				let authentication = try await chargeSettlementProvider.authorize(
					paymentId: paymentContext.paymentId,
				)

				// Navigate to the charge start screen with the updated charge request and authentication
				let authenticatedRequest = AuthenticatedChargeRequest(
					request,
					authentication: authentication,
				)

				router.chargeStartRouter.reset()
				navigationRoot.path.append(Router.Destination.chargeStart(request: authenticatedRequest))
			case .canceled:
				break
			case let .failed(error):
				Elvah.logger.error("Failed to pay: \(error)")
				router.showGenericError = true
			}
		} catch {
			Elvah.logger.error("Failed to pay: \(error.localizedDescription)")
			router.showGenericError = true
		}
	}
}

extension PaymentSheet {
	static var empty: PaymentSheet {
		PaymentSheet(paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration())
	}

	static func from(clientSecret: String) -> PaymentSheet {
		var configuration = PaymentSheet.Configuration()
		configuration.returnURL = "elvah://stripe-redirect"
		configuration.savePaymentMethodOptInBehavior = .requiresOptOut
		return PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
	}
}

@available(iOS 16.0, *)
extension ChargePaymentFeature {
	final class Router: BaseRouter {
		enum Destination: Hashable {
			case chargeStart(request: AuthenticatedChargeRequest)
		}

		@Published var showLegalLinkOptions = false
		@Published var showPaymentSheet = false
		@Published var showGenericError = false
		@Published var showOfferUnavailableSheet = false

		let supportSheetRouter = SupportFeature.Router()
		let chargeStartRouter = ChargeStartFeature.Router()

		func dismissPresentation() {
			showLegalLinkOptions = false
			showPaymentSheet = false
			showGenericError = false
			showOfferUnavailableSheet = false
		}

		func reset() {
			dismissPresentation()
			supportSheetRouter.reset()
			chargeStartRouter.reset()
		}
	}
}

@available(iOS 16.0, *)
#Preview {
	NavigationStack {
		ChargePaymentFeature(request: .mock, router: .init())
	}
	.preferredColorScheme(.dark)
	.withFontRegistration()
}
