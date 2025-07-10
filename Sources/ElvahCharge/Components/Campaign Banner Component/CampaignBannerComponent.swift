// Copyright © elvah. All rights reserved.

import CoreLocation
import MapKit
import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
package struct ChargeBannerComponent: View {
	@Environment(\.dynamicTypeSize) private var dynamicTypeSize
	@Default(.chargeSessionContext) private var chargeSessionContext
	@EnvironmentObject private var chargeProvider: ChargeProvider

	private var source: ChargeBannerSource.Binding
	private var variant: ChargeBannerVariant
	private var action: (_ destination: ChargeBannerActionDestination) -> Void

	@TaskIdentifier private var chargeSessionTaskId
	private var chargeSessionRefreshId: ChargeSessionRefreshIdentifier {
		ChargeSessionRefreshIdentifier(
			id: chargeSessionTaskId,
			chargeSessionContext: chargeSessionContext
		)
	}

	private var sourceExpiryWrapper: SourceExpiryWrapper? {
		guard let chargeSite = source.chargeSite.data else {
			return nil
		}
		return SourceExpiryWrapper(hasEnded: source.hasEnded, chargeSite: chargeSite)
	}

	package init(
		source: ChargeBannerSource.Binding,
		variant: ChargeBannerVariant = .large,
		action: @escaping (_ destination: ChargeBannerActionDestination) -> Void
	) {
		self.source = source
		self.variant = variant
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
		case let .chargeSite(chargeSite):
			action(.chargeSitePresentation(chargeSite))
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
		if let chargeSite = source.chargeSite.data {
			return .loaded(.chargeSite(chargeSite))
		}

		if let error = source.chargeSite.error {
			return .error(error)
		}

		if source.chargeSite.isLoading {
			return .loading
		}

		// Finally, return .absent if nothing is loading or loaded
		return .absent
	}
}

@available(iOS 16.0, *)
package extension ChargeBannerComponent {
	struct SourceExpiryWrapper: Equatable {
		var hasEnded: Bool
		var chargeSite: ChargeSite
	}

	struct ChargeSessionRefreshIdentifier: Equatable {
		var id: UUID
		var chargeSessionContext: ChargeSessionContext?
	}

	enum ViewState {
		case chargeSite(ChargeSite)
		case chargeSession(ChargeSession)

		var isChargeSession: Bool {
			if case .chargeSession = self {
				return true
			}
			return false
		}

		var isChargeSite: Bool {
			if case .chargeSite = self {
				return true
			}
			return false
		}
	}
}

@available(iOS 17.0, *)
#Preview("Dynamic") { @MainActor in
	@Previewable @ChargeBannerSource(
		display: .whenSourceSet,
		provider: .mock
	) var chargeBannerSource = nil
	@Previewable @Default(.chargeSessionContext) var chargeSessionContext

	ScrollView {
		VStack {
			if let $chargeBannerSource {
				ChargeBannerComponent(source: $chargeBannerSource) { _ in }
				ChargeBannerComponent(source: $chargeBannerSource, variant: .compact) { _ in }
			}
		}
		.padding()
		.frame(maxWidth: .infinity)
		.animation(.default, value: chargeBannerSource)
	}
	.safeAreaInset(edge: .bottom) {
		FooterView {
			ButtonStack {
				ButtonStack(axis: .horizontal) {
					Button("Location") {
						chargeBannerSource = .remote(near: .init())
					}
					.disabled(chargeBannerSource.usesLocation)
					Button("Region") {
						chargeBannerSource = .remote(in: .mock)
					}
					.disabled(chargeBannerSource.usesRegion)
					Button("Campaign") {
						chargeBannerSource = .direct(.mock)
					}
					.disabled(chargeBannerSource.usesCampaign)
				}
				Button("Reset") {
					chargeBannerSource = nil
				}
				.disabled(chargeBannerSource.isEmpty)
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
	let source = ChargeBannerSource.Binding(
		chargeSite: .absent,
		chargeSession: .constant(.absent),
		hasEnded: false,
		kind: .remoteInRegion(.mock),
		triggerReload: {}
	)

	VStack {
		ChargeBannerComponent(source: source) { _ in }
		ChargeBannerComponent(source: source, variant: .compact) { _ in }
	}
	.padding()
	.withFontRegistration()
	.preferredColorScheme(.dark)
	.withMockEnvironmentObjects()
}
