// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package struct ChargeOfferDetailFeature: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject private var router: ChargeOfferDetailFeature.Router
	@EnvironmentObject private var chargeProvider: ChargeProvider
	@EnvironmentObject private var chargeSettlementProvider: ChargeSettlementProvider

	private var associatedSite: Site?

	@State private var processingDeal: Deal?
	@State private var scrollPosition = CGPoint.zero
	@TaskIdentifier private var reloadTaskId
	@Loadable<Site> private var site
	@Loadable<[Deal]> private var deals
	@Loadable<Double?> private var routeDistanceToStation
	@Process private var paymentInitiation

	package init(deals: [Deal], router: ChargeOfferDetailFeature.Router) {
		_deals = Loadable(wrappedValue: .loaded(deals))
		self.router = router
	}

	package var body: some View {
		content
			.animation(.default, value: site)
			.animation(.default, value: routeDistanceToStation)
			.foregroundStyle(.primaryContent)
			.toolbarBackground(.canvas, for: .navigationBar)
			.task {
				await reloadContinuously()
			}
			.task(id: reloadTaskId) {
				guard let associatedSite else {
					$site.reset()
					return
				}

				await reloadData(for: associatedSite)
			}
			.onChange(of: associatedSite) { associatedSite in
				$reloadTaskId.new()
				if let associatedSite {
					site = .loaded(associatedSite)
				}
			}
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					CloseButton()
				}
			}
			.background {
				VStack(spacing: 0) {
					Color.canvas.ignoresSafeArea().frame(height: max(0, scrollPosition.y))
					Color.container.ignoresSafeArea()
				}
			}
			.onChange(of: paymentInitiation) { paymentInitiation in
				if paymentInitiation.hasFailed {
					router.showGenericError = true
				}
			}
			.genericErrorBottomSheet(isPresented: $router.showGenericError)
			.fullScreenCover(item: $router.chargeRequest) { chargeRequest in
				ChargeEntryFeature(chargeRequest: chargeRequest)
			}
			.fullScreenCover(isPresented: $router.showChargeEntry) {
				ChargeEntryFeature()
			}
			.confirmationDialog("Open with", isPresented: $router.showRouteOptions) {
				if let site = site.data {
					Button("Apple Maps", bundle: .elvahCharge) {
						site.openDirectionsInAppleMaps()
					}
					Button("Google Maps", bundle: .elvahCharge) {
						site.openDirectionsInGoogleMaps()
					}
					Button("Back", role: .cancel, bundle: .elvahCharge) {
						router.showRouteOptions = false
					}
				}
			}
	}

	@ViewBuilder private var content: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {
				if associatedSite != nil {
					siteContent
				}
				dealsContent
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.padding(.vertical, 16)
		}
		.coordinateSpace(name: "ScrollView")
	}

	@ViewBuilder private var siteContent: some View {
		switch site {
		case .absent,
				.loading:
			ActivityInfoComponent(state: .animating, title: nil, message: nil)
				.frame(maxWidth: .infinity)
		case .error:
			EmptyView()
		case let .loaded(site):
			if let operatorName = site.operatorName, let address = site.address {
				header(title: operatorName, address: address)
			}
			routeButton
		}
	}


	@ViewBuilder private var dealsContent: some View {
		ChargeOfferDetailFeature.ChargePointSection(
			initialPowerTypeSelection: site.data?.prevalentPowerType,
			deals: deals,
			dealsSectionOrigin: $scrollPosition,
			processingDeal: processingDeal,
			dealAction: { deal in
				handleChargePointTap(for: deal)
			},
			chargeSessionAction: {
				router.showChargeEntry = true
			}
		)
		.disabled(paymentInitiation.isRunning)
		.animation(.default, value: paymentInitiation)
	}

	@ViewBuilder private func header(title: String, address: Site.Address) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(title)
				.typography(.title(size: .small), weight: .bold)
				.foregroundStyle(.primaryContent)
			Text(address.formatted())
				.typography(.copy(size: .medium))
				.foregroundStyle(.secondaryContent)
				.dynamicTypeSize(...(.accessibility2))
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.multilineTextAlignment(.leading)
		.padding(.horizontal, 16)
	}

	@ViewBuilder private var routeButton: some View {
		Button("Route", icon: .directions) {
			router.showRouteOptions = true
		}
		.controlSize(.small)
		.invertedButtonLabel()
		.buttonStyle(.primary)
		.padding(.horizontal, 16)
	}

	// MARK: - Actions

	/// Returns a copy of the view with the given site associated for displaying site-specific
	/// information.
	/// - Parameter site: The site.
	/// - Returns: A ``ChargeOfferDetailFeature`` configured to show information about the site.
	package func siteInformation(_ site: Site?) -> some View {
		var copy = self
		copy.associatedSite = site
		if let site {
			copy._site = .init(wrappedValue: .loaded(site))
		} else {
			copy._site = .init(wrappedValue: .absent)
		}
		return copy
	}

	private func reloadData(for associatedSite: Site) async {
		site = .loaded(associatedSite)
	}

	private func reloadContinuously() async {
		do {
			while !Task.isCancelled {
				try await Task.sleep(for: .seconds(60))
				$reloadTaskId.new()
			}
		} catch {}
	}

	private func handleChargePointTap(for deal: Deal) {
		guard let site = site.data else {
			return
		}

		$paymentInitiation.run {
			defer { processingDeal = nil }
			processingDeal = deal
			let context = try await chargeSettlementProvider.initiate(signedOffer: deal.signedDeal)
			try Task.checkCancellation()
			router.chargeRequest = ChargeRequest(site: site, deal: deal, paymentContext: context)
		}
	}
}

@available(iOS 16.0, *)
package extension ChargeOfferDetailFeature {
	@MainActor
	final class Router: BaseRouter {
		@Published var showGenericError = false
		@Published var showRouteOptions = false
		@Published var showChargeEntry = false
		@Published var chargeRequest: ChargeRequest?

		let chargePaymentRouter = ChargePaymentFeature.Router()

		package func reset() {
			showGenericError = false
			showRouteOptions = false
			showChargeEntry = false
			chargeRequest = nil
			chargePaymentRouter.reset()
		}
	}
}

@available(iOS 16.0, *)
#Preview {
	NavigationStack {
		ChargeOfferDetailFeature(
			deals: [.mockAvailable, .mockUnavailable, .mockOutOfService],
			router: .init()
		)
		.siteInformation(.mock)
	}
	.withFontRegistration()
	.withMockEnvironmentObjects()
	.preferredColorScheme(.dark)
}
