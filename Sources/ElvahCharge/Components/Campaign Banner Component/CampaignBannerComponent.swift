// Copyright © elvah. All rights reserved.

import CoreLocation
import MapKit
import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
package struct CampaignBannerComponent: View {
	@Environment(\.dynamicTypeSize) private var dynamicTypeSize
	@Default(.chargeSessionContext) private var chargeSessionContext
	@EnvironmentObject private var chargeProvider: ChargeProvider

	private var source: CampaignSource.Binding
	private var variant: CampaignBannerVariant
	private var action: (_ destination: CampaignBannerActionDestination) -> Void
	private var onCampaignEnd: CampaignBanner.CampaignEndedBlock?

	@TaskIdentifier private var chargeSessionTaskId
	private var chargeSessionRefreshId: ChargeSessionRefreshIdentifier {
		ChargeSessionRefreshIdentifier(
			id: chargeSessionTaskId,
			chargeSessionContext: chargeSessionContext
		)
	}

	private var sourceExpiryWrapper: SourceExpiryWrapper? {
		guard let campaign = source.campaign.data else {
			return nil
		}
		return SourceExpiryWrapper(hasEnded: source.hasEnded, campaign: campaign)
	}

	package init(
		source: CampaignSource.Binding,
		variant: CampaignBannerVariant = .large,
		onCampaignEnd: CampaignBanner.CampaignEndedBlock? = nil,
		action: @escaping (_ destination: CampaignBannerActionDestination) -> Void
	) {
		self.source = source
		self.variant = variant
		self.onCampaignEnd = onCampaignEnd
		self.action = action
	}

	package var body: some View {
		VStack(spacing: 0) {
			header
			switch variant {
			case .large:
				largeContent
			case .compact:
				smallContent
			}
		}
		.frame(maxWidth: .infinity)
		.transformEffect(.identity)
		.clipShape(.rect(cornerRadius: 12))
		.dynamicTypeSize(...(.accessibility1))
		.onAppear {
			if Defaults[.chargeSessionContext] != nil {
				source.chargeSession.setLoading()
			}
		}
		.onChange(of: sourceExpiryWrapper) { wrapper in
			guard let wrapper, wrapper.hasEnded else {
				return
			}
			onCampaignEnd?(wrapper.campaign)
		}
		.task(id: chargeSessionRefreshId) {
			await observeChargeSession(using: chargeSessionContext)
		}
	}

	@ViewBuilder private var header: some View {
		Header(
			source: source,
			viewState: viewState,
			primaryAction: handleButtonAction,
			retryAction: reloadData
		)
	}

	@ViewBuilder private var largeContent: some View {
		LargeContent(
			source: source,
			viewState: viewState,
			primaryAction: handleButtonAction,
			retryAction: reloadData
		)
	}

	@ViewBuilder private var smallContent: some View {
		SmallContent(source: source, viewState: viewState) {
			handleButtonAction()
		}
	}

	private func handleButtonAction() {
		if chargeSessionContext != nil {
			action(.chargeSessionPresentation)
			return
		}

		guard let loadedData = viewState.data else {
			return
		}

		switch loadedData {
		case let .campaign(campaign):
			action(.campaignDetailPresentation(campaign))
		case .chargeSession:
			action(.chargeSessionPresentation)
		}
	}

	// MARK: - Actions

	private func reloadData() {
		$chargeSessionTaskId.new()

		guard source.kind?.isReloadable == true else {
			return
		}

		source.triggerReload()
	}

	private func observeChargeSession(using chargeSessionContext: ChargeSessionContext?) async {
		guard let chargeSessionContext else {
			source.chargeSession.setAbsent()
			return
		}

		source.chargeSession.setLoading()

		do {
			let authentication = chargeSessionContext.authentication
			let sessionUpdates = await chargeProvider.sharedSessionUpdates(with: authentication)
			for try await session in sessionUpdates {
				source.chargeSession.setValue(session)
			}
		} catch {
			source.chargeSession.setError(error)
		}
	}

	private var viewState: LoadableState<ViewState> {
		// Check for charge session loadable state
		if let chargeSession = source.chargeSession.data {
			return .loaded(.chargeSession(chargeSession))
		}

		if let error = source.chargeSession.error {
			return .error(error)
		}

		if source.chargeSession.isLoading {
			return .loading
		}

		// If the view hasn't set source.chargeSession yet, but there is definitely an active
		// charge session, we set the view state to loading to prevent glitches in the UI
		// (which could happen when using a .direct() source)
		if Defaults[.chargeSessionContext] != nil {
			return .loading
		}

		// Otherwise check for campaign loadable state
		if let campaign = source.campaign.data {
			return .loaded(.campaign(campaign))
		}

		if let error = source.campaign.error {
			return .error(error)
		}

		if source.campaign.isLoading {
			return .loading
		}

		// Finally, return .absent if nothing is loading or loaded
		return .absent
	}
}

@available(iOS 16.0, *)
package extension CampaignBannerComponent {
	struct SourceExpiryWrapper: Equatable {
		var hasEnded: Bool
		var campaign: Campaign
	}

	struct ChargeSessionRefreshIdentifier: Equatable {
		var id: UUID
		var chargeSessionContext: ChargeSessionContext?
	}

	enum ViewState {
		case campaign(Campaign)
		case chargeSession(ChargeSession)

		var isChargeSession: Bool {
			if case .chargeSession = self {
				return true
			}
			return false
		}

		var isCampaign: Bool {
			if case .campaign = self {
				return true
			}
			return false
		}
	}
}

@available(iOS 17.0, *)
#Preview("Dynamic") { @MainActor in
	@Previewable @CampaignSource(
		display: .whenSourceSet,
		provider: .mock
	) var campaignSource = nil
	@Previewable @Default(.chargeSessionContext) var chargeSessionContext

	ScrollView {
		VStack {
			if let $campaignSource {
				CampaignBannerComponent(source: $campaignSource) { _ in }
				CampaignBannerComponent(source: $campaignSource, variant: .compact) { _ in }
			}
		}
		.padding()
		.frame(maxWidth: .infinity)
		.animation(.default, value: campaignSource)
	}
	.safeAreaInset(edge: .bottom) {
		FooterView {
			ButtonStack {
				ButtonStack(axis: .horizontal) {
					Button("Location") {
						campaignSource = .remote(near: .init())
					}
					.disabled(campaignSource.usesLocation)
					Button("Region") {
						campaignSource = .remote(in: .mock)
					}
					.disabled(campaignSource.usesRegion)
					Button("Campaign") {
						campaignSource = .direct(.mock)
					}
					.disabled(campaignSource.usesCampaign)
				}
				Button("Reset") {
					campaignSource = nil
				}
				.disabled(campaignSource.isEmpty)
				Divider()
				ButtonStack(axis: .horizontal) {
					Button("No Session") {
						chargeSessionContext = nil
					}
					.disabled(Defaults[.chargeSessionContext] == nil)
					Button("With Session") {
						chargeSessionContext = ChargeSessionContext(
							site: .mock,
							signedOffer: .mockAvailable,
							organisationDetails: .mock,
							authentication: .mock,
							paymentId: "",
							startedAt: Date()
						)
					}
					.disabled(Defaults[.chargeSessionContext] != nil)
				}
				.buttonStyle(.secondary)
			}
			.dynamicTypeSize(.large)
			.buttonStyle(.primary)
		}
	}
	.withFontRegistration()
	.preferredColorScheme(.dark)
	.withMockEnvironmentObjects()
}

@available(iOS 17.0, *)
#Preview("Static") {
	let source = CampaignSource.Binding(
		campaign: .absent,
		chargeSession: .constant(.absent),
		hasEnded: false,
		kind: .remoteInRegion(.mock),
		triggerReload: {}
	)

	VStack {
		CampaignBannerComponent(source: source) { _ in }
		CampaignBannerComponent(source: source, variant: .compact) { _ in }
	}
	.padding()
	.withFontRegistration()
	.preferredColorScheme(.dark)
	.withMockEnvironmentObjects()
}
