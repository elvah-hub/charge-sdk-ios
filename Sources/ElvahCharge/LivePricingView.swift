// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Core)
	import Core
#endif

/// A drop‑in SwiftUI view that presents live charging prices for a charge site.
///
/// The view shows the current price per kWh, power details,
/// and a time‑based price chart that highlights upcoming offer windows. An optional
/// primary action allows users to start a charge from within the component,
/// without any additional setup in your code.
///
/// ## Usage
/// ```swift
/// struct StationDetailScreen: View {
/// 	var schedule: ChargeSiteSchedule
///
/// 	var body: some View {
/// 		LivePricingView(schedule: schedule)
/// 	}
/// }
/// ```
///
/// ## Getting a Schedule
/// ```swift
/// // From a ChargeSite instance
/// let schedule = try await chargeSite.pricingSchedule()
///
/// // Or using the static accessor on ChargeSiteSchedule
/// let schedule = try await ChargeSiteSchedule.schedule(for: chargeSite)
///
/// // Completion‑based variant
/// let observer = ChargeSiteSchedule.schedule(for: chargeSite) { result in
///     // handle Result<ChargeSiteSchedule, Elvah.Error>
/// }
/// ```
///
/// ## Customization
/// ```swift
/// LivePricingView(schedule: schedule)
/// 	.operatorDetailsHidden()   // hide operator + address header
/// 	.chargeButtonHidden()      // hide "Charge now" button
/// ```
public struct LivePricingView: View {
	@StateObject private var router = LivePricingView.Router()

	/// The pricing schedule to visualize.
	private var schedule: ChargeSiteSchedule

	/// Whether to hide operator details in the schedule header.
	private var isOperatorDetailsHidden = false

	/// Whether to hide the charge button.
	private var isChargeButtonHidden = false

	/// Creates a live pricing view for a given pricing schedule.
	/// - Note: On iOS versions earlier than 16, the view renders as an empty placeholder.
	///
	/// - Parameter schedule: The price timeline to display, including the
	///   current price and upcoming price windows for the selected site.
	public init(schedule: ChargeSiteSchedule) {
		self.schedule = schedule
	}

	public var body: some View {
		if #available(iOS 16.0, *) {
			PricingScheduleView(
				schedule: schedule,
				router: router,
				isOperatorDetailsHidden: isOperatorDetailsHidden,
				isChargeButtonHidden: isChargeButtonHidden
			)
			.fullScreenCover(item: $router.chargeOfferDetail) { siteSchedule in
				ChargeOfferDetailRootFeature(site: nil, offers: siteSchedule.chargeSite.offers)
			}
			.withEnvironmentObjects()
		} else {
			EmptyView()
		}
	}
}

public extension LivePricingView {
	/// Hides the operator and address details shown in the schedule header.
	///
	/// Use this when the surrounding screen already provides that context.
	/// - Parameter hide: Whether the header details should be hidden. Defaults to `true`.
	/// - Returns: A copy of the view with the preference applied.
	///
	/// Example
	/// ```swift
	/// LivePricingView(schedule: schedule)
	/// 	.operatorDetailsHidden()
	/// ```
	func operatorDetailsHidden(_ hide: Bool = true) -> LivePricingView {
		var copy = self
		copy.isOperatorDetailsHidden = hide
		return copy
	}

	/// Hides the "Charge now" call‑to‑action displayed beneath the chart.
	///
	/// Use this when you provide your own primary action elsewhere on the screen.
	/// - Parameter hide: Whether the charge button should be hidden. Defaults to `true`.
	/// - Returns: A copy of the view with the preference applied.
	///
	/// Example
	/// ```swift
	/// LivePricingView(schedule: schedule)
	/// 	.chargeButtonHidden()
	/// ```
	func chargeButtonHidden(_ hide: Bool = true) -> LivePricingView {
		var copy = self
		copy.isChargeButtonHidden = hide
		return copy
	}
}

package extension LivePricingView {
	final class Router: BaseRouter {
		@Published var chargeOfferDetail: ChargeSiteSchedule?
		@Published var showChargeSession = false

		package func reset() {
			chargeOfferDetail = nil
			showChargeSession = false
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	LivePricingView(schedule: .mock)
		.withFontRegistration()
		.preferredColorScheme(.dark)
}
