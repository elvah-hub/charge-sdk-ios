// Copyright © elvah. All rights reserved.

import CoreLocation
import MapKit
import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

/// A property wrapper that manages campaign data loading and state for a ``ChargeBanner`` view.
///
/// The source determines how campaign data is loaded, controlling the presentation and state of the
/// banner. Available loading methods include:
/// - Loading campaigns near a location
/// - Loading campaigns within a map region
/// - Using a provided campaign directly
///
/// You can configure how the ``ChargeBanner`` responds to campaign availability using the
/// ``ChargeBannerSource/DisplayBehavior`` parameter:
///
/// ```swift
/// // Always show banner when a source is set (default)
/// @ChargeBannerSource private var chargeBannerSource
///
/// // Only show banner when a campaign is available
/// @ChargeBannerSource(display: .whenContentAvailable) private var chargeBannerSource
/// ```
///
/// ## Loading Campaigns
///
/// ```swift
/// // Load nearest campaign at a location
/// chargeBannerSource = .remote(near: myLocation)
///
/// // Load campaign in a map region
/// chargeBannerSource = .remote(in: mapRegion)
///
/// // Use campaign directly
/// chargeBannerSource = .direct(campaign)
/// ```
///
/// ## Reset Source
/// To reset the campaign source, set it to `nil`:
///
/// ```swift
/// chargeBannerSource = nil
/// ```
///
/// See ``ChargeBanner`` for detailed implementation examples and a complete overview of the
/// campaign presentation mechanism.
@MainActor @propertyWrapper
public struct ChargeBannerSource: DynamicProperty {
	@Default(.chargeSessionContext) private var chargeSessionContext
	private let discoveryProvider: DiscoveryProvider
	@SwiftUI.State private var internalState: ChargeBannerSource.State
	@SwiftUI.State private var displayBehavior: DisplayBehavior
	@SwiftUI.State private var loadingTask: Task<Void, Never>?

	/// Initializes the ``ChargeBannerSource``.
	/// - Parameter wrappedValue: The initial campaign source. Defaults to `nil`.
	/// - Parameter displayBehavior: The display behavior controlling the presentation of the attached
	/// ``ChargeBanner`` view depending on the availability of a campaign. Defaults to
	/// ``ChargeBannerSource/DisplayBehavior/whenSourceSet``.
	public init(
		wrappedValue: ChargeBannerSource.State? = nil,
		display displayBehavior: DisplayBehavior = .whenSourceSet
	) {
		_internalState = SwiftUI.State(initialValue: wrappedValue ?? .none)
		_displayBehavior = SwiftUI.State(initialValue: displayBehavior)
		discoveryProvider = DiscoveryProvider.live
	}

	/// The current state of the campaign source.
	///
	/// - Tip: This object conforms to the `Equatable`. You can pass it to an `.animation(_:value:)`
	/// view modifier to control the animation of internal state changes of the ``ChargeBanner``
	/// view.
	public var wrappedValue: ChargeBannerSource.State? {
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

	/// A binding to the internal state that you can pass to the ``ChargeBanner`` view.
	///
	/// The returned value is `nil` when no source is set or other internal conditions are met. You
	/// can unwrap it as you would any other optional and then pass it to the ``ChargeBanner`` view.
	///
	/// ```swift
	/// if let $chargeBannerSource {
	///   CampaignBaner(source: $chargeBannerSource)
	/// }
	/// ```
	public var projectedValue: ChargeBannerSource.Binding? {
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

		return ChargeBannerSource.Binding(
			chargeSite: internalState.chargeSite,
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
		return internalState.chargeSite.isLoaded || internalState.hasPreviouslyLoadedData
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
					var chargeSite: ChargeSite?

					// Attempt to load an active campaign
					switch kind {
					case let .remoteNearLocation(location):
						stateBinding.wrappedValue.chargeSite.setLoading()
						chargeSite = try await discoveryProvider.sites(near: location).first

					case let .remoteInRegion(region):
						stateBinding.wrappedValue.chargeSite.setLoading()
						chargeSite = try await discoveryProvider.sites(in: region).first

					case let .direct(directChargeSite):
						chargeSite = directChargeSite
					}

					// If no charge site could be found, we can return
					guard let chargeSite, let cheapestOffer = chargeSite.cheapestOffer else {
						stateBinding.wrappedValue.chargeSite.setAbsent()
						return
					}

					// Set internal state
					// TODO: cheapest offer should be part of the state, not decided by the view
					stateBinding.wrappedValue.chargeSite.setValue(chargeSite)
					stateBinding.wrappedValue.hasEnded = false
					stateBinding.wrappedValue.hasPreviouslyLoadedData = true

					if let campaign = cheapestOffer.campaign {
						if campaign.hasEnded {
							// Campaign has ended, we can return early.
							stateBinding.wrappedValue.chargeSite.setAbsent()
							stateBinding.wrappedValue.hasEnded = true
							return
						}

						// Now wait for campaign expiry and the set the campaign source expiry value
						let sleepTime = Duration.seconds(campaign.endDate.timeIntervalSinceNow)
						try await Task.sleep(for: sleepTime, tolerance: .seconds(1))
						stateBinding.wrappedValue.hasEnded = true
					}
				}
			} catch is CancellationError {} catch {
				print("\(error.localizedDescription)")
				Elvah.internalLogger.error("Failed to load campaign: \(error.localizedDescription)")
				stateBinding.wrappedValue.chargeSite.setError(error)
			}
		}
	}
}

public extension ChargeBannerSource {
	/// The current state of the campaign source.
	struct State: Equatable, Sendable {
		/// A unique identifier for the source.
		var id: UUID

		/// The loading state of the charge site data.
		var chargeSite: LoadableState<ChargeSite>

		/// Indicates if the campaign has ended.
		var hasEnded: Bool

		/// The loading state of the charge session.
		var chargeSession: LoadableState<ChargeSession>

		/// The method used to fetch the campaign.
		var kind: Kind?

		/// A flag indicating if the loading process is the first one after a new source has been set.
		///
		/// A ``ChargeBannerSource`` with a ``ChargeBannerSource/DisplayBehavior/whenContentAvailable``
		/// will
		/// only hide the banner on the first loading of a newly set source. Subsequent refreshes, to
		/// replace expired campaigns, will not hide the banner.
		var hasPreviouslyLoadedData = false

		package init(
			id: UUID = UUID(),
			chargeSite: LoadableState<ChargeSite>,
			kind: Kind?,
			hasEnded: Bool = false,
			chargeSession: LoadableState<ChargeSession> = .absent,
			hasPreviouslyLoadedData: Bool = false
		) {
			self.id = id
			self.chargeSite = chargeSite
			self.kind = kind
			self.hasEnded = hasEnded
			self.chargeSession = chargeSession
			self.hasPreviouslyLoadedData = hasPreviouslyLoadedData
		}

		/// A default empty state with no campaign loaded.
		///
		/// This state will cause ``ChargeBannerSource/projectedValue`` to be `nil`.
		package static var none: ChargeBannerSource.State {
			ChargeBannerSource.State(chargeSite: .absent, kind: nil)
		}

		/// Creates a state to load the nearest campaign for a given location.
		/// - Parameter location: The coordinate to fetch the campaign nearest to it.
		/// - Returns: A state configured to fetch by location.
		public static func remote(near location: CLLocationCoordinate2D) -> ChargeBannerSource.State {
			ChargeBannerSource.State(chargeSite: .loading, kind: .remoteNearLocation(location))
		}

		/// Creates a state to load a campaign within a given region.
		/// - Parameter region: The map region to fetch the campaign in.
		/// - Returns: A state configured to fetch by region.
		public static func remote(in region: MKMapRect) -> ChargeBannerSource.State {
			ChargeBannerSource.State(chargeSite: .loading, kind: .remoteInRegion(region))
		}

		/// Creates a state with a provided campaign.
		///
		/// You can use this if you want to handle the loading of a campaign yourself. You can fetch
		/// a campaing by calling ``Campaign/campaigns(in:)`` or one of its overloads.
		///
		/// - Parameter campaign: The campaign object to use.
		/// - Returns: A state using the given campaign directly.
		public static func direct(_ chargeSite: ChargeSite) -> ChargeBannerSource.State {
			ChargeBannerSource.State( chargeSite: .loaded(chargeSite), kind: .direct(chargeSite)
			)
		}
	}

	/// A binding to the internal campaign state that can be passed to a ``ChargeBanner`` view.
	struct Binding {
		var chargeSite: LoadableState<ChargeSite>
		@SwiftUI.Binding var chargeSession: LoadableState<ChargeSession>
		var hasEnded: Bool
		var kind: Kind?
		var triggerReload: () -> Void
	}

	enum DisplayBehavior {
		/// Always shows the attached ``ChargeBanner`` view as long as a source is set.
		///
		/// This will cause visible loading and error states in the ``ChargeBanner`` view. If no
		/// campaigns can be found, the banner will show a "no deals found" message.
		case whenSourceSet

		/// Only show the attached ``ChargeBanner`` view when a campaign is loaded and ready to be
		/// shown.
		///
		/// This will entirely hide loading and error states, also preventing a "no deals found" message
		/// that could clutter up your view hierarchy. Instead, the banner will only ever appear when a
		/// campaign is available.
		case whenContentAvailable
	}

	/// The method that should be used to fetch the charge site data for the ``ChargeBanner`` view.
	package enum Kind: Equatable {
		/// Fetch the nearest charge site at the given coordinates.
		case remoteNearLocation(CLLocationCoordinate2D)

		/// Fetch a charge site within the specified map region.
		case remoteInRegion(MKMapRect)

		/// Use a provided charge site object directly.
		case direct(ChargeSite)

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

public extension ChargeBannerSource.State? {
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

extension ChargeBannerSource {
	init(
		wrappedValue: ChargeBannerSource.State? = nil,
		display displayBehavior: DisplayBehavior = .whenSourceSet,
		provider: DiscoveryProvider
	) {
		_internalState = SwiftUI.State(initialValue: wrappedValue ?? .none)
		_displayBehavior = SwiftUI.State(initialValue: displayBehavior)
		discoveryProvider = provider
	}
}
