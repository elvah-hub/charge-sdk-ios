// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package struct ChargeOfferDetailFeature: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject private var router: ChargeOfferDetailFeature.Router
	@EnvironmentObject private var discoveryProvider: DiscoveryProvider
	@EnvironmentObject private var chargeProvider: ChargeProvider
	@EnvironmentObject private var chargeSettlementProvider: ChargeSettlementProvider

	private var associatedSite: Site?

	@State private var processingOffer: ChargeOffer?
	@State private var scrollPosition = CGPoint.zero
	@TaskIdentifier private var reloadTaskId
	@Loadable<Site> private var site
	@Loadable<[ChargeOffer]> private var offers
	@Loadable<Double?> private var routeDistanceToStation
	@Process private var paymentInitiation

	/// The charge offer that is used to determine the date at which the campaign ends, if there is one active.
	///
	/// While campaigns live inside each charge point, all charge points on a site share the same campaign end date,
	/// so the detail view can just grab any offer and reads its campaign details.
	@State private var discountedOfferRepresentative: ChargeOffer?

	/// Whether to hide operator details in the header.
	private var isOperatorDetailsHidden = false

	/// Whether to hide the discount banner above the charge points list.
	private var isDiscountBannerHidden = false

	package init(
		offers: [ChargeOffer],
		router: ChargeOfferDetailFeature.Router,
		hideOperatorDetails: Bool = false,
		hideDiscountBanner: Bool = false,
	) {
		_offers = Loadable(wrappedValue: .loaded(offers))
		self.router = router
		isOperatorDetailsHidden = hideOperatorDetails
		isDiscountBannerHidden = hideDiscountBanner
	}

	package var body: some View {
		content
			.animation(.default, value: site)
			.animation(.default, value: routeDistanceToStation)
			.foregroundStyle(.primaryContent)
			.navigationBarTitleDisplayMode(.inline)
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
			.task(id: loadedOfferIdentifiers) {
				await updateDiscountBannerLifecycle()
			}
			.onChange(of: associatedSite) { associatedSite in
				$reloadTaskId.new()
				if let associatedSite {
					site = .loaded(associatedSite)
				}
			}
			.toolbar {
				ToolbarItem(placement: .principal) {
					StyledNavigationTitle("Select charge point", bundle: .elvahCharge)
				}
				ToolbarItem(placement: .topBarLeading) {
					CloseButton()
				}
			}
			.toolbarBackground(.canvas, for: .navigationBar)
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
	}

	@ViewBuilder private var content: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: .size(.L)) {
				if let discountedOfferRepresentative {
					discountBanner(for: discountedOfferRepresentative)
				}
				VStack(alignment: .leading, spacing: .size(.L)) {
					if associatedSite != nil {
						siteContent
					}
					chargePointsContent
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.padding(.bottom, .size(.M))
			}
		}
		.scrollDismissesKeyboard(.interactively)
		.coordinateSpace(name: "ScrollView")
	}

	@ViewBuilder private var siteContent: some View {
		switch site {
		case .absent,
		     .loading:
			EmptyView()
				.progressRing()
				.frame(maxWidth: .infinity)
		case .error:
			EmptyView()
		case let .loaded(site):
			if isOperatorDetailsHidden == false, let operatorName = site.operatorName, let address = site.address {
				header(title: operatorName, address: address)
			}
		}
	}

	@ViewBuilder private func discountBanner(for discountedOffer: ChargeOffer) -> some View {
		TimelineView(.periodic(from: .now, by: 1)) { context in
			HStack(spacing: .size(.XS)) {
				Image(.localOffer)
					.foregroundStyle(.brand)
				OfferEndLabel(
					offer: discountedOffer,
					referenceDate: context.date,
					prefix: "Offer available for ",
					primaryColor: .brand,
				)
				.typography(.copy(size: .small), weight: .bold)
				.foregroundStyle(.brand)
			}
			.padding(.XS)
			.frame(maxWidth: .infinity)
			.multilineTextAlignment(.center)
			.background(.brand.opacity(0.2))
			.transition(.move(edge: .top))
		}
	}

	@ViewBuilder private func header(title: String, address: Site.Address) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(title)
				.typography(.title(size: .small), weight: .bold)
				.foregroundStyle(.primaryContent)
			Button {
				router.showRouteOptions = true
			} label: {
				HStack(spacing: .size(.XXS)) {
					Text(address.formatted())
						.underline()
						.typography(.copy(size: .medium))
						.foregroundStyle(.secondaryContent)
					Image(.openInNew)
						.foregroundStyle(.secondaryContent)
				}
			}
			.buttonStyle(.plain)
			.dynamicTypeSize(...(.accessibility2))
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
		.frame(maxWidth: .infinity, alignment: .leading)
		.multilineTextAlignment(.leading)
		.padding(.horizontal, 16)
	}

	@ViewBuilder private var chargePointsContent: some View {
		ChargeOfferDetailFeature.ChargePointSection(
			offers: offers,
			offersSectionOrigin: $scrollPosition,
			processingOffer: processingOffer,
			isDiscountBannerHidden: isDiscountBannerHidden,
			offerAction: { offer in
				handleChargePointTap(for: offer)
			},
			chargeSessionAction: {
				router.showChargeEntry = true
			},
		)
		.disabled(paymentInitiation.isRunning)
		.animation(.default, value: paymentInitiation)
	}

	private func updateDiscountBannerLifecycle() async {
		guard case let .loaded(loadedOffers) = offers else {
			discountedOfferRepresentative = nil
			return
		}

		guard let discounted = loadedOffers.first(where: { $0.isDiscounted && $0.isAvailable }) else {
			discountedOfferRepresentative = nil
			return
		}

		discountedOfferRepresentative = discounted

		guard let campaign = discounted.campaign else {
			return
		}

		let remainingSeconds = campaign.endDate.timeIntervalSinceNow

		guard remainingSeconds > 0 else {
			discountedOfferRepresentative = nil
			return
		}

		do {
			try await Task.sleep(for: .seconds(remainingSeconds))
			discountedOfferRepresentative = nil
		} catch is CancellationError {} catch {
			discountedOfferRepresentative = nil
		}
	}

	/// Identifiers of the currently loaded offers used for change observation.
	private var loadedOfferIdentifiers: [String] {
		guard case let .loaded(loadedOffers) = offers else {
			return []
		}
		return loadedOffers.map(\.id)
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

	private func handleChargePointTap(for offer: ChargeOffer) {
		let site = site.data ?? offer.site

		$paymentInitiation.run {
			defer { processingOffer = nil }
			processingOffer = offer

			let signedOffer = try await discoveryProvider.signOffer(offer)
			let context = try await chargeSettlementProvider.initiate(with: signedOffer.token)
			try Task.checkCancellation()

			router.chargeRequest = ChargeRequest(
				site: site,
				signedOffer: signedOffer,
				paymentContext: context,
			)
		}
	}
}

@available(iOS 16.0, *)
package extension ChargeOfferDetailFeature {
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
			offers: [.mockAvailable, .mockUnavailable, .mockOutOfService],
			router: .init(),
		)
		.siteInformation(.mock)
	}
	.withFontRegistration()
	.withMockEnvironmentObjects()
	.preferredColorScheme(.dark)
}
