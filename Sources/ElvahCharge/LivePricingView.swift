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

	/// Optional horizontal inset to apply to certain subcomponents.
	///
	/// When set, this value is passed down to internal components and used as
	/// the horizontal padding for the header and the primary action button.
	/// The chart remains edge‑to‑edge. If `nil`, the system default padding is used.
	private var horizontalAreaPaddings: [ComponentArea: CGFloat] = [:]

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
				isChargeButtonHidden: isChargeButtonHidden,
				horizontalAreaPaddings: horizontalAreaPaddings,
			)
			.accessibilityElement(children: .contain)
			.fullScreenCover(item: $router.chargeOfferDetail) { siteSchedule in
				ChargeOfferDetailRootFeature(site: nil, offers: siteSchedule.chargeSite.offers)
			}
			.sheet(isPresented: $router.isShowingOtherPricesSheet) {
				ChargeSitePricingInfoFeature(chargeSite: schedule.chargeSite)
			}
			.withEnvironmentObjects()
		} else {
			EmptyView()
		}
	}
}

public extension LivePricingView {
	struct ComponentArea: OptionSet, Sendable, Hashable {
		public let rawValue: Int
		public static let header = ComponentArea(rawValue: 1 << 0)
		public static let footer = ComponentArea(rawValue: 1 << 1)
		public static let all: ComponentArea = [.header, .footer]

		public init(rawValue: Int) {
			self.rawValue = rawValue
		}
	}
}

// MARK: - View Modification

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

	/// Applies horizontal padding to specific areas within the component.
	///
	/// The padding is applied only to the provided areas (for example, the
	/// header and the primary action). The price chart always renders
	/// edge‑to‑edge and does not accept horizontal padding because it is a
	/// scroll view.
	///
	/// - Important: Avoid adding a global horizontal padding to
	///   `LivePricingView` itself, as that would also inset the chart and can
	///   make the scrollable content appear visually cut off. Prefer this
	///   targeted modifier instead.
	///
	/// - Parameters:
	///   - value: The horizontal padding, in points. Pass `nil` to use the
	///     system default.
	///   - areas: The component areas that should receive the padding (for
	///     example, `.header`, `.footer`, or `.all`).
	/// - Returns: A copy of the view with the horizontal padding applied to the
	///   specified areas.
	///
	/// Example
	/// ```swift
	/// LivePricingView(schedule: schedule)
	///     .padding(16, for: [.header, .footer])
	/// ```
	func padding(_ value: CGFloat?, for areas: ComponentArea) -> LivePricingView {
		var copy = self

		if areas.contains(.header) {
			copy.horizontalAreaPaddings[.header] = value
		}

		if areas.contains(.footer) {
			copy.horizontalAreaPaddings[.footer] = value
		}

		return copy
	}
}

package extension LivePricingView {
	final class Router: BaseRouter {
		@Published var chargeOfferDetail: ChargeSiteSchedule?
		@Published var showChargeSession = false
		@Published var isShowingOtherPricesSheet = false

		package func reset() {
			chargeOfferDetail = nil
			showChargeSession = false
			isShowingOtherPricesSheet = false
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	LivePricingView(schedule: .mock)
		.withFontRegistration()
		.preferredColorScheme(.dark)
}
