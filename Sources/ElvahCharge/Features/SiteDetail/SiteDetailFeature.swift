// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package struct SiteDetailFeature: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject private var router: SiteDetailFeature.Router
	@EnvironmentObject private var chargeProvider: ChargeProvider
	@EnvironmentObject private var chargeSettlementProvider: ChargeSettlementProvider

	@State private var processingDeal: Deal?
	@State private var scrollPosition = CGPoint.zero
	@TaskIdentifier private var reloadTaskId
	@Loadable<Site> private var site
	@Loadable<[Deal]> private var deals
	@Loadable<Double?> private var routeDistanceToStation
	@Process private var paymentInitiation

	package init(site: Site, deals: [Deal], router: SiteDetailFeature.Router) {
		_site = Loadable(wrappedValue: .loaded(site))
		_deals = Loadable(wrappedValue: .loaded(deals))
		self.router = router
	}

	package var body: some View {
		Group {
			switch site {
			case .absent,
			     .loading,
			     .error:
				activityContent
			case let .loaded(site):
				siteContent(for: site)
			}
		}
		.animation(.default, value: site)
		.animation(.default, value: routeDistanceToStation)
		.foregroundStyle(.primaryContent)
		.toolbarBackground(.canvas, for: .navigationBar)
		.task(id: reloadTaskId) {
			await reloadData()
		}
		.task {
			await reloadContinuously()
		}
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				CloseButton {
					dismiss()
				}
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

	@ViewBuilder private func siteContent(for site: Site) -> some View {
		ScrollView {
			VStack(spacing: 0) {
				VStack(alignment: .leading, spacing: 24) {
					if let operatorName = site.operatorName, let address = site.address {
						header(title: operatorName, address: address)
					}
					routeButton
					SiteDetailFeature.ChargePointSection(
						site: site,
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
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.padding(.vertical, 16)
		}
		.coordinateSpace(name: "ScrollView")
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

	@ViewBuilder private var openingHours: some View {
		Button {} label: {
			HStack(spacing: 2) {
				VStack(spacing: 4) {
					Text("Opening hours", bundle: .elvahCharge)
					Rectangle().frame(height: 1)
				}
				.fixedSize(horizontal: true, vertical: false)
				Image("expandMore", bundle: .elvahCharge)
			}
		}
		.foregroundStyle(.primaryContent)
		.typography(.copy(size: .medium), weight: .bold)
		.padding(.horizontal, 16)
	}

	@ViewBuilder private var activityContent: some View {
		var title: LocalizedStringKey? {
			if site.isError {
				return "An error occurred"
			}
			return "Loading site"
		}

		var message: LocalizedStringKey? {
			if site.isError {
				return "The site could not be loaded. Please try again later."
			}
			return nil
		}

		var state: ActivityInfoComponent.ActivityState {
			if site.isError {
				return .error
			}
			return .animating
		}

		ActivityInfoComponent(state: state, title: title, message: message)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	// MARK: - Actions

	private func reloadData() async {}

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
package extension SiteDetailFeature {
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
		SiteDetailFeature(
			site: .mock,
			deals: [.mockAvailable, .mockUnavailable, .mockOutOfService],
			router: .init()
		)
	}
	.withFontRegistration()
	.withMockEnvironmentObjects()
	.preferredColorScheme(.dark)
}
