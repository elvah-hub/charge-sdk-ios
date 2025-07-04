// Copyright © elvah. All rights reserved.

import CoreLocation
import MapKit
import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

/// A property wrapper that manages campaign data loading and state for a ``CampaignBanner`` view.
///
/// The source determines how campaign data is loaded, controlling the presentation and state of the
/// banner. Available loading methods include:
/// - Loading campaigns near a location
/// - Loading campaigns within a map region
/// - Using a provided campaign directly
///
/// You can configure how the ``CampaignBanner`` responds to campaign availability using the
/// ``CampaignSource/DisplayBehavior`` parameter:
///
/// ```swift
/// // Always show banner when a source is set (default)
/// @CampaignSource private var campaignSource
///
/// // Only show banner when a campaign is available
/// @CampaignSource(display: .whenContentAvailable) private var campaignSource
/// ```
///
/// ## Loading Campaigns
///
/// ```swift
/// // Load nearest campaign at a location
/// campaignSource = .remote(near: myLocation)
///
/// // Load campaign in a map region
/// campaignSource = .remote(in: mapRegion)
///
/// // Use campaign directly
/// campaignSource = .direct(campaign)
/// ```
///
/// ## Reset Source
/// To reset the campaign source, set it to `nil`:
///
/// ```swift
/// campaignSource = nil
/// ```
///
/// See ``CampaignBanner`` for detailed implementation examples and a complete overview of the
/// campaign presentation mechanism.
@MainActor @propertyWrapper
public struct CampaignSource: DynamicProperty {
	@Default(.chargeSessionContext) private var chargeSessionContext
	private let discoveryProvider: DiscoveryProvider
	@SwiftUI.State private var internalState: CampaignSource.State
	@SwiftUI.State private var displayBehavior: DisplayBehavior
	@SwiftUI.State private var loadingTask: Task<Void, Never>?

	/// Initializes the ``CampaignSource``.
	/// - Parameter wrappedValue: The initial campaign source. Defaults to `nil`.
	/// - Parameter displayBehavior: The display behavior controlling the presentation of the attached
	/// ``CampaignBanner`` view depending on the availability of a campaign. Defaults to
	/// ``CampaignSource/DisplayBehavior/whenSourceSet``.
	public init(
		wrappedValue: CampaignSource.State? = nil,
		display displayBehavior: DisplayBehavior = .whenSourceSet
	) {
		_internalState = SwiftUI.State(initialValue: wrappedValue ?? .none)
		_displayBehavior = SwiftUI.State(initialValue: displayBehavior)
		discoveryProvider = DiscoveryProvider.live
	}

	/// The current state of the campaign source.
	///
	/// - Tip: This object conforms to the `Equatable`. You can pass it to an `.animation(_:value:)`
	/// view modifier to control the animation of internal state changes of the ``CampaignBanner``
	/// view.
	public var wrappedValue: CampaignSource.State? {
		get {
			if internalState.kind == nil {
				return nil
			}
			return internalState
		}
		nonmutating set {
			let oldStateId = internalState.id
			internalState = newValue ?? .none
			let newStateId = internalState.id

			if newStateId != oldStateId {
				reloadCampaign()
			}
		}
	}

	/// A binding to the internal state that you can pass to the ``CampaignBanner`` view.
	///
	/// The returned value is `nil` when no source is set or other internal conditions are met. You
	/// can unwrap it as you would any other optional and then pass it to the ``CampaignBanner`` view.
	///
	/// ```swift
	/// if let $campaignSource {
	///   CampaignBaner(source: $campaignSource)
	/// }
	/// ```
	public var projectedValue: CampaignSource.Binding? {
		// Only return a value if the user is running iOS 16 or above.
		guard #available(iOS 16.0, *) else {
			return nil
		}

		// Only return a value, if a source has been set
		guard let kind = internalState.kind else {
			return nil
		}

		guard shouldShowBanner else {
			return nil
		}

		// Provide a mechanism to trigger a reload of the campaign data.
		let triggerReloadAction = {
			reloadCampaign()
		}

		return CampaignSource.Binding(
			campaign: internalState.campaign,
			chargeSession: $internalState.chargeSession,
			hasEnded: internalState.hasEnded,
			kind: kind,
			triggerReload: triggerReloadAction
		)
	}

	private var shouldShowBanner: Bool {
		// Always show when display behavior is .whenSourceSet
		if displayBehavior == .whenSourceSet {
			return true
		}

		// Always show if there is an active charge session
		if chargeSessionContext != nil {
			return true
		}

		// Don't show if campaign has ended
		if internalState.hasEnded {
			return false
		}

		// Show if we have content OR this is a refresh (not initial load)
		return internalState.campaign.isLoaded || internalState.hasPreviouslyLoadedData
	}

	// MARK: - Campaign Loading

	private func reloadCampaign() {
		guard #available(iOS 16.0, *) else {
			Elvah.logger.info("Loading a campaign is not support for iOS 15. This is a no-nop.")
			return
		}

		let stateBinding = $internalState

		// Cancel any ongoing loading task.
		loadingTask?.cancel()

		// If the kind is `nil`, we don't need to load anything.
		guard let kind = stateBinding.wrappedValue.kind else {
			return
		}

		loadingTask = Task {
			do {
				while Task.isCancelled == false {
					var campaign: Campaign?

					// Attempt to load an active campaign
					switch kind {
					case let .remoteNearLocation(location):
						stateBinding.wrappedValue.campaign.setLoading()
						campaign = try await discoveryProvider.deals(near: location).first

					case let .remoteInRegion(region):
						stateBinding.wrappedValue.campaign.setLoading()
						campaign = try await discoveryProvider.deals(in: region).first

					case let .direct(directCampaign):
						campaign = directCampaign
					}

					// If there's no active campaign, we can return
					guard let campaign else {
						stateBinding.wrappedValue.campaign.setAbsent()
						return
					}

					// Campaign has ended, we can return early.
					guard campaign.hasEnded == false,
									let latestEndingOffer = campaign.chargeSite.latestEndingOffer else {
						stateBinding.wrappedValue.campaign.setAbsent()
						stateBinding.wrappedValue.hasEnded = campaign.hasEnded
						return
					}

					// Set internal state
					stateBinding.wrappedValue.campaign.setValue(campaign)
					stateBinding.wrappedValue.hasEnded = false
					stateBinding.wrappedValue.hasPreviouslyLoadedData = true

					// Wait for campaign expiry and the set the campaign source expiry value
					let sleepTime = Duration.seconds(latestEndingOffer.campaignEndDate.timeIntervalSinceNow)
					try await Task.sleep(for: sleepTime, tolerance: .seconds(1))
					stateBinding.wrappedValue.hasEnded = true
				}
			} catch is CancellationError {} catch {
				print("\(error.localizedDescription)")
				Elvah.internalLogger.error("Failed to load campaign: \(error.localizedDescription)")
				stateBinding.wrappedValue.campaign.setError(error)
			}
		}
	}
}

public extension CampaignSource {
	/// The current state of the campaign source.
	struct State: Equatable, Sendable {
		/// A unique identifier for the source.
		var id: UUID

		/// The loading state of the campaign data.
		var campaign: LoadableState<Campaign>

		/// Indicates if the campaign has ended.
		var hasEnded: Bool

		/// The loading state of the charge session.
		var chargeSession: LoadableState<ChargeSession>

		/// The method used to fetch the campaign.
		var kind: Kind?

		/// A flag indicating if the loading process is the first one after a new source has been set.
		///
		/// A ``CampaignSource`` with a ``CampaignSource/DisplayBehavior/whenContentAvailable`` will
		/// only hide the banner on the first loading of a newly set source. Subsequent refreshes, to
		/// replace expired campaigns, will not hide the banner.
		var hasPreviouslyLoadedData = false

		package init(
			id: UUID = UUID(),
			campaign: LoadableState<Campaign>,
			kind: Kind?,
			hasEnded: Bool = false,
			chargeSession: LoadableState<ChargeSession> = .absent,
			hasPreviouslyLoadedData: Bool = false
		) {
			self.id = id
			self.campaign = campaign
			self.kind = kind
			self.hasEnded = hasEnded
			self.chargeSession = chargeSession
			self.hasPreviouslyLoadedData = hasPreviouslyLoadedData
		}

		/// A default empty state with no campaign loaded.
		///
		/// This state will cause ``CampaignSource/projectedValue`` to be `nil`.
		package static var none: CampaignSource.State {
			CampaignSource.State(campaign: .absent, kind: nil)
		}

		/// Creates a state to load the nearest campaign for a given location.
		/// - Parameter location: The coordinate to fetch the campaign nearest to it.
		/// - Returns: A state configured to fetch by location.
		public static func remote(near location: CLLocationCoordinate2D) -> CampaignSource.State {
			CampaignSource.State(campaign: .loading, kind: .remoteNearLocation(location))
		}

		/// Creates a state to load a campaign within a given region.
		/// - Parameter region: The map region to fetch the campaign in.
		/// - Returns: A state configured to fetch by region.
		public static func remote(in region: MKMapRect) -> CampaignSource.State {
			CampaignSource.State(campaign: .loading, kind: .remoteInRegion(region))
		}

		/// Creates a state with a provided campaign.
		///
		/// You can use this if you want to handle the loading of a campaign yourself. You can fetch
		/// a campaing by calling ``Campaign/campaigns(in:)`` or one of its overloads.
		///
		/// - Parameter campaign: The campaign object to use.
		/// - Returns: A state using the given campaign directly.
		public static func direct(_ campaign: Campaign) -> CampaignSource.State {
			CampaignSource.State(
				campaign: .loaded(campaign),
				kind: .direct(campaign),
				hasEnded: campaign.hasEnded
			)
		}
	}

	/// A binding to the internal campaign state that can be passed to a ``CampaignBanner`` view.
	struct Binding {
		var campaign: LoadableState<Campaign>
		@SwiftUI.Binding var chargeSession: LoadableState<ChargeSession>
		var hasEnded: Bool
		var kind: Kind?
		var triggerReload: () -> Void
	}

	enum DisplayBehavior {
		/// Always shows the attached ``CampaignBanner`` view as long as a source is set.
		///
		/// This will cause visible loading and error states in the ``CampaignBanner`` view. If no
		/// campaigns can be found, the banner will show a "no deals found" message.
		case whenSourceSet

		/// Only show the attached ``CampaignBanner`` view when a campaign is loaded and ready to be
		/// shown.
		///
		/// This will entirely hide loading and error states, also preventing a "no deals found" message
		/// that could clutter up your view hierarchy. Instead, the banner will only ever appear when a
		/// campaign is available.
		case whenContentAvailable
	}

	/// The method that should be used to fetch the campaign data for the ``CampaignBanner`` view.
	package enum Kind: Equatable {
		/// Fetch the nearest campaign at the given coordinates.
		case remoteNearLocation(CLLocationCoordinate2D)

		/// Fetch a campaign within the specified map region.
		case remoteInRegion(MKMapRect)

		/// Use a provided campaign object directly.
		case direct(Campaign)

		/// A boolean indicating if the campaign data can be reloaded in case on an error.
		package var isReloadable: Bool {
			if case .direct = self {
				return false
			}
			return true
		}

		public static func == (lhs: Kind, rhs: Kind) -> Bool {
			switch (lhs, rhs) {
			case let (.remoteNearLocation(left), .remoteNearLocation(right)):
				return left.latitude == right.latitude
					&& left.longitude == right.longitude
			case let (.remoteInRegion(left), .remoteInRegion(right)):
				return left.origin.x == right.origin.x
					&& left.origin.y == right.origin.y
					&& left.size.width == right.size.width
					&& left.size.height == right.size.height
			case (.direct, .direct):
				return true
			default:
				return false
			}
		}
	}
}

// MARK: - Campaign State Helpers

public extension CampaignSource.State? {
	/// Returns `true` if the campaign state is currently `nil`.
	var isEmpty: Bool {
		if self != nil {
			return false
		}
		return true
	}

	/// Returns `true` if the campaign state is set to fetch using a location.
	var usesLocation: Bool {
		guard let self else {
			return false
		}

		if case .remoteNearLocation = self.kind {
			return true
		}
		return false
	}

	/// Returns `true` if the campaign state is set to fetch using a map region.
	var usesRegion: Bool {
		guard let self else {
			return false
		}

		if case .remoteInRegion = self.kind {
			return true
		}
		return false
	}

	/// Returns `true` if the campaign state is using a provided campaign directly.
	var usesCampaign: Bool {
		guard let self else {
			return false
		}

		if case .direct = self.kind {
			return true
		}
		return false
	}
}

// MARK: - Debug Helpers

extension CampaignSource {
	init(
		wrappedValue: CampaignSource.State? = nil,
		display displayBehavior: DisplayBehavior = .whenSourceSet,
		provider: DiscoveryProvider
	) {
		_internalState = SwiftUI.State(initialValue: wrappedValue ?? .none)
		_displayBehavior = SwiftUI.State(initialValue: displayBehavior)
		discoveryProvider = provider
	}
}
