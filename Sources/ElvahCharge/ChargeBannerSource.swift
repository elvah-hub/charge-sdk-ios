// Copyright © elvah. All rights reserved.

import CoreLocation
import MapKit
import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

/// A property wrapper that manages charge offer data loading and state for a ``ChargeBanner`` view.
///
/// The source determines how charge offer data is loaded, controlling the presentation and state of
/// the
/// banner. Available loading methods include:
/// - Loading offers near a location
/// - Loading offers within a map region
/// - Loading offers for a specific set of evse ids
/// - Using a charge site directly
///
/// You can configure how the ``ChargeBanner`` responds to charge offer availability using the
/// ``ChargeBannerSource/DisplayBehavior`` parameter:
///
/// ```swift
/// // Always show banner when a source is set (default)
/// @ChargeBannerSource private var chargeBannerSource
///
/// // Only show deals that are par of a campaign
/// @ChargeBannerSource(fetching: .campaigns) private var chargeBannerSource
///
/// // Only show banner when a charge offer is available
/// @ChargeBannerSource(display: .whenContentAvailable) private var chargeBannerSource
/// ```
///
/// ## Loading Campaigns
///
/// ```swift
/// // Load nearest charge offer at a location
/// chargeBannerSource = .remote(near: myLocation)
///
/// // Load a charge offer in a map region
/// chargeBannerSource = .remote(in: mapRegion)
///
/// // Use a charge offer from a list of specific evse ids
/// chargeBannerSource = .remote(evseIds: someEvseIds)
///
/// // Use charge site directly
/// chargeBannerSource = .direct(chargeSite)
/// ```
///
/// ## Reset Source
/// To reset the source, set it to `nil`:
///
/// ```swift
/// chargeBannerSource = nil
/// ```
///
/// See ``ChargeBanner`` for detailed implementation examples and a complete overview of the
/// charge offer presentation mechanism.
@MainActor @propertyWrapper
public struct ChargeBannerSource: DynamicProperty {
	@Default(.chargeSessionContext) private var chargeSessionContext
	private let discoveryProvider: DiscoveryProvider
	@SwiftUI.State private var internalState: ChargeBannerSource.State
	@SwiftUI.State private var displayBehavior: DisplayBehavior
	@SwiftUI.State private var fetchKind: FetchKind
	@SwiftUI.State private var loadingTask: Task<Void, Never>?

	/// Initializes the ``ChargeBannerSource``.
	/// - Parameter wrappedValue: The initial source. Defaults to `nil`.
	/// - Parameter fetchKind: The fetch configuration for the charge offers. Defaults to
	/// ``ChargeBannerSource/FetchKind/allOffers``.
	/// - Parameter displayBehavior: The display behavior controlling the presentation of the attached
	/// ``ChargeBanner`` view depending on the availability of a charge offer. Defaults to
	/// ``ChargeBannerSource/DisplayBehavior/whenSourceSet``.
	public init(
		wrappedValue: ChargeBannerSource.State? = nil,
		fetching fetchKind: FetchKind = .allOffers,
		display displayBehavior: DisplayBehavior = .whenSourceSet
	) {
		_internalState = SwiftUI.State(initialValue: wrappedValue ?? .none)
		_fetchKind = SwiftUI.State(initialValue: fetchKind)
		_displayBehavior = SwiftUI.State(initialValue: displayBehavior)
		// TODO: Add Support for simulation
		discoveryProvider = DiscoveryProvider.live
	}

	/// The current state of the source.
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
				reloadChargeOffer()
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

		// Provide a mechanism to trigger a reload of the charge offer data.
		let triggerReloadAction = {
			reloadChargeOffer()
		}

		return ChargeBannerSource.Binding(
			chargeSite: internalState.chargeSite,
			offer: internalState.offer,
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

		// Don't show if charge offer (if it's a campaign) has ended
		if internalState.hasEnded {
			return false
		}

		// Show if we have content OR this is a refresh (not initial load)
		return internalState.offer.isLoaded || internalState.hasPreviouslyLoadedData
	}

	// MARK: - Charge Offer Loading

	private func reloadChargeOffer() {
		guard #available(iOS 16.0, *) else {
			Elvah.logger.info("Loading an offer is not support for iOS 15. This is a no-nop.")
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

					// Attempt to load an active charge offer
					switch kind {
					case let .remoteNearLocation(location):
						stateBinding.wrappedValue.offer.setLoading()
						switch fetchKind {
						case .allOffers:
							chargeSite = try await discoveryProvider.sites(near: location).first
						case .campaigns:
							chargeSite = try await discoveryProvider.campaigns(near: location).first
						}

					case let .remoteInRegion(region):
						stateBinding.wrappedValue.offer.setLoading()
						switch fetchKind {
						case .allOffers:
							chargeSite = try await discoveryProvider.sites(in: region).first
						case .campaigns:
							chargeSite = try await discoveryProvider.campaigns(in: region).first
						}

					case let .remoteForEvseIds(evseIds):
						stateBinding.wrappedValue.offer.setLoading()
						switch fetchKind {
						case .allOffers:
							chargeSite = try await discoveryProvider.sites(forEvseIds: evseIds).first
						case .campaigns:
							chargeSite = try await discoveryProvider.campaigns(forEvseIds: evseIds).first
						}

					case let .direct(directChargeSite):
						chargeSite = directChargeSite
					}

					// If no charge site could be found, we can return
					guard let chargeSite else {
						stateBinding.wrappedValue.chargeSite.setAbsent()
						stateBinding.wrappedValue.offer.setAbsent()
						return
					}

					// If no offer could be found, we can return
					guard let cheapestOffer = chargeSite.cheapestOffer else {
						stateBinding.wrappedValue.offer.setAbsent()
						return
					}

					// Set internal state
					stateBinding.wrappedValue.chargeSite.setValue(chargeSite)
					stateBinding.wrappedValue.offer.setValue(cheapestOffer)
					stateBinding.wrappedValue.hasEnded = false
					stateBinding.wrappedValue.hasPreviouslyLoadedData = true

					if let campaign = cheapestOffer.campaign {
						if campaign.hasEnded {
							// Campaign has ended, we can return early.
							stateBinding.wrappedValue.offer.setAbsent()
							stateBinding.wrappedValue.hasEnded = true
							return
						}

						// Now wait for campaign expiry and the set the campaign source expiry value
						let sleepTime = Duration.seconds(campaign.endDate.timeIntervalSinceNow)
						try await Task.sleep(for: sleepTime, tolerance: .seconds(1))
						stateBinding.wrappedValue.hasEnded = true
					} else {
						// End loop here because the offer does not end
						break
					}
				}
			} catch is CancellationError {} catch {
				Elvah.internalLogger.error("Failed to load campaign: \(error.localizedDescription)")
				stateBinding.wrappedValue.chargeSite.setError(error)
				stateBinding.wrappedValue.offer.setError(error)
			}
		}
	}
}

public extension ChargeBannerSource {
	/// The current state of the source.
	struct State: Equatable, Sendable {
		/// A unique identifier for the source.
		var id: UUID

		/// The loading state of the charge site data.
		var chargeSite: LoadableState<ChargeSite>

		/// The loading state of the charge offer that is presented by the banner
		var offer: LoadableState<ChargeOffer>

		/// Indicates if the offer has ended, which will only happen if it's part of a campaign.
		var hasEnded: Bool

		/// The loading state of the charge session.
		var chargeSession: LoadableState<ChargeSession>

		/// The method used to fetch the charge offer.
		var kind: Kind?

		/// A flag indicating if the loading process is the first one after a new source has been set.
		var hasPreviouslyLoadedData = false

		package init(
			id: UUID = UUID(),
			chargeSite: LoadableState<ChargeSite>,
			offer: LoadableState<ChargeOffer>,
			kind: Kind?,
			hasEnded: Bool = false,
			chargeSession: LoadableState<ChargeSession> = .absent,
			hasPreviouslyLoadedData: Bool = false
		) {
			self.id = id
			self.chargeSite = chargeSite
			self.offer = offer
			self.kind = kind
			self.hasEnded = hasEnded
			self.chargeSession = chargeSession
			self.hasPreviouslyLoadedData = hasPreviouslyLoadedData
		}

		/// A default empty state with no charge offer loaded.
		///
		/// This state will cause ``ChargeBannerSource/projectedValue`` to be `nil`.
		package static var none: ChargeBannerSource.State {
			ChargeBannerSource.State(
				chargeSite: .loading,
				offer: .loading,
				kind: nil
			)
		}

		/// Creates a state to load charge offers nearest a given location.
		///
		/// - Note: There is no guarantee that a charge offer can be found or is available.
		/// - Parameter location: The coordinate to fetch the charge offer nearest to it.
		/// - Returns: A state configured to fetch by location.
		public static func remote(near location: CLLocationCoordinate2D) -> ChargeBannerSource.State {
			ChargeBannerSource.State(
				chargeSite: .loading,
				offer: .loading,
				kind: .remoteNearLocation(location)
			)
		}

		/// Creates a state to load charge offers within a given region.
		///
		/// - Note: There is no guarantee that a charge offer can be found or is available.
		/// - Parameter region: The map region to fetch the charge offer in.
		/// - Returns: A state configured to fetch by region.
		public static func remote(in region: MKMapRect) -> ChargeBannerSource.State {
			ChargeBannerSource.State(
				chargeSite: .loading,
				offer: .loading,
				kind: .remoteInRegion(region)
			)
		}

		/// Creates a state to load charge offers from a list of evse ids.
		///
		/// - Note: There is no guarantee that a charge offer can be found or is available.
		/// - Parameter evseIds: The evse ids to fetch charge offers from.
		/// - Returns: A state configured to fetch by region.
		public static func remote(evseIds: [String]) -> ChargeBannerSource.State {
			ChargeBannerSource.State(
				chargeSite: .loading,
				offer: .loading,
				kind: .remoteForEvseIds(evseIds)
			)
		}

		/// Creates a state with a provided charge site obect.
		///
		/// You can use this if you want to handle the loading of a charge site and its offers yourself.
		/// You can fetch
		/// a site by calling ``ChargeSite/sites(in:)``, ``ChargeSite/campaigns(in:)`` or one of their
		/// respective overloads.
		///
		/// - Parameter chargeSite: The charge site object to use.
		/// - Returns: A state using the given charge site directly.
		public static func direct(_ chargeSite: ChargeSite) -> ChargeBannerSource.State {
			var offer = LoadableState<ChargeOffer>.loading

			if let cheapestOffer = chargeSite.cheapestOffer {
				offer = .loaded(cheapestOffer)
			}

			return ChargeBannerSource.State(
				chargeSite: .loaded(chargeSite),
				offer: offer,
				kind: .direct(chargeSite)
			)
		}
	}

	/// A binding to the internal state that can be passed to a ``ChargeBanner`` view.
	struct Binding {
		var chargeSite: LoadableState<ChargeSite>
		var offer: LoadableState<ChargeOffer>
		@SwiftUI.Binding var chargeSession: LoadableState<ChargeSession>
		var hasEnded: Bool
		var kind: Kind?
		var triggerReload: () -> Void
	}

	enum FetchKind {
		/// A configuration that fetches all charge offer from the given source.
		case allOffers

		/// A configuration that fetches only charges offer from an active campaign using the given
		/// source.
		case campaigns
	}

	enum DisplayBehavior {
		/// Always shows the attached ``ChargeBanner`` view as long as a source is set.
		///
		/// This will cause visible loading and error states in the ``ChargeBanner`` view. If no
		/// charge offer can be found, the banner will show a "no deals found" message.
		case whenSourceSet

		/// Only show the attached ``ChargeBanner`` view when a charge offer is loaded and ready to be
		/// shown.
		///
		/// This will entirely hide loading and error states, also preventing a "no deals found" message
		/// that could clutter up your view hierarchy. Instead, the banner will only ever appear when a
		/// charge offer is available.
		case whenContentAvailable
	}

	/// The method that should be used to fetch the charge site data for the ``ChargeBanner`` view.
	package enum Kind: Equatable {
		/// Fetch the nearest charge offer at the given coordinates.
		case remoteNearLocation(CLLocationCoordinate2D)

		/// Fetch charge offers within the specified map region.
		case remoteInRegion(MKMapRect)

		/// Fetch charge offers with the given evse ids.
		case remoteForEvseIds([String])

		/// Use a provided charge site object directly.
		case direct(ChargeSite)

		/// A boolean indicating if the charge offer data can be reloaded in case on an error.
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
			case let (.remoteForEvseIds(left), .remoteForEvseIds(right)):
				return left == right
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
	/// Returns `true` if the state is currently `nil`.
	var isEmpty: Bool {
		if self != nil {
			return false
		}
		return true
	}

	/// Returns `true` if the state is set to fetch using a location.
	var usesLocation: Bool {
		guard let self else {
			return false
		}

		if case .remoteNearLocation = self.kind {
			return true
		}
		return false
	}

	/// Returns `true` if the state is set to fetch using a map region.
	var usesRegion: Bool {
		guard let self else {
			return false
		}

		if case .remoteInRegion = self.kind {
			return true
		}
		return false
	}

	/// Returns `true` if the state is set to fetch using a list of evse ids.
	var usesEvseIds: Bool {
		guard let self else {
			return false
		}

		if case .remoteForEvseIds = self.kind {
			return true
		}
		return false
	}

	/// Returns `true` if the state is using a provided charge site directly.
	var usesChargeSite: Bool {
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
		fetching fetchKind: FetchKind = .allOffers,
		display displayBehavior: DisplayBehavior = .whenSourceSet,
		provider: DiscoveryProvider
	) {
		_internalState = SwiftUI.State(initialValue: wrappedValue ?? .none)
		_fetchKind = SwiftUI.State(initialValue: fetchKind)
		_displayBehavior = SwiftUI.State(initialValue: displayBehavior)
		discoveryProvider = provider
	}
}
